package com.gamelearn.phase;

import static org.assertj.core.api.Assertions.*;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.User;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;
import com.gamelearn.service.CreditService;
import com.gamelearn.repository.CreditLedgerRepository;
import com.gamelearn.repository.UserCreditRepository;
import com.gamelearn.exception.ApiException;

@SpringBootTest
@ActiveProfiles("test")
class CreditServicePhaseL1Test {

    @Autowired UserRepository userRepository;
    @Autowired XpTransactionRepository xpTransactionRepository;
    @Autowired CreditService creditService;
    @Autowired UserCreditRepository userCreditRepository;
    @Autowired CreditLedgerRepository creditLedgerRepository;

    // CRED-01: credit calculation from valid XP award
    @Test
    @Transactional
    void cred01_creditDerivedFromXp() {
        User user = userRepository.save(PersistenceTestFixtures.user("credit01"));
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, 10);
        xp = xpTransactionRepository.save(xp);
        int c = creditService.awardForXpTransaction(user, xp);
        assertThat(c).isEqualTo(6); // floor(10*0.6)
        assertThat(creditService.balance(user.getId())).isEqualTo(6);
    }

    // CRED-02: zero XP gives zero credit
    @Test
    @Transactional
    void cred02_zeroXpZeroCredit() {
        User user = userRepository.save(PersistenceTestFixtures.user("credit02"));
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, 0);
        xp.setAmount(0);
        xp = xpTransactionRepository.save(xp);
        int c = creditService.awardForXpTransaction(user, xp);
        assertThat(c).isEqualTo(0);
        assertThat(creditService.balance(user.getId())).isEqualTo(0);
        assertThat(creditLedgerRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).isEmpty();
    }

    // CRED-03: credit amount never negative
    @Test
    void cred03_creditAmountNeverNegative() {
        assertThat(CreditService.creditsForXp(10)).isGreaterThanOrEqualTo(0);
        assertThat(CreditService.creditsForXp(0)).isEqualTo(0);
        assertThat(CreditService.creditsForXp(-5)).isEqualTo(0);
        assertThat(CreditService.creditsForXp(100)).isEqualTo(60);
    }

    // CRED-04: duplicate XP transaction cannot duplicate credit award (idempotency)
    @Test
    @Transactional
    void cred04_duplicateXpCannotDuplicateCredit() {
        User user = userRepository.save(PersistenceTestFixtures.user("credit04"));
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, 25);
        xp = xpTransactionRepository.save(xp);
        int first = creditService.awardForXpTransaction(user, xp);
        int second = creditService.awardForXpTransaction(user, xp);
        assertThat(first).isEqualTo(15); // floor(25*0.6)
        assertThat(second).isEqualTo(0);
        assertThat(creditService.balance(user.getId())).isEqualTo(15);
        assertThat(creditLedgerRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).hasSize(1);
    }

    // CRED-05: credit purchase cannot make balance negative
    @Test
    @Transactional
    void cred05_purchaseCannotMakeNegative() {
        User user = userRepository.save(PersistenceTestFixtures.user("credit05"));
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, 10);
        xp = xpTransactionRepository.save(xp);
        creditService.awardForXpTransaction(user, xp); // 6
        assertThatThrownBy(() -> creditService.spend(user, 100, UUID.randomUUID()))
                .isInstanceOf(ApiException.class);
        assertThat(creditService.balance(user.getId())).isEqualTo(6);
    }

    // CRED-08: credit + ownership rollback covered in avatar purchase tests but verify balance remains after failed spend
    @Test
    @Transactional
    void cred08_balanceUnchangedAfterFailedSpend() {
        User user = userRepository.save(PersistenceTestFixtures.user("credit08"));
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, 20);
        xp = xpTransactionRepository.save(xp);
        creditService.awardForXpTransaction(user, xp); // 12
        try { creditService.spend(user, 999, UUID.randomUUID()); } catch (Exception ignored) {}
        assertThat(creditService.balance(user.getId())).isEqualTo(12);
        assertThat(creditLedgerRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).hasSize(1);
    }
}
