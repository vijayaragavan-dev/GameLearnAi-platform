package com.gamelearn.service;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.CreditLedger;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserCredit;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.CreditLedgerRepository;
import com.gamelearn.repository.UserCreditRepository;

/**
 * Credits domain (Phase L1) — separate cosmetic currency derived from XP.
 * Server-authoritative; never client-supplied.
 * Derivation: floor(xpAmount * 0.60). Zero XP => zero credits, no ledger row.
 * Idempotency: one credit_ledger row per (user, reference_type, reference_id).
 */
@Service
public class CreditService {

    private static final Logger log = LoggerFactory.getLogger(CreditService.class);
    static final int CREDIT_FACTOR_NUMERATOR = 60;
    static final int CREDIT_FACTOR_DENOMINATOR = 100;

    private final UserCreditRepository userCreditRepository;
    private final CreditLedgerRepository creditLedgerRepository;

    public CreditService(UserCreditRepository userCreditRepository,
                         CreditLedgerRepository creditLedgerRepository) {
        this.userCreditRepository = userCreditRepository;
        this.creditLedgerRepository = creditLedgerRepository;
    }

    /**
     * Derive credits from a freshly persisted XpTransaction.
     * Idempotent: if a ledger row already exists for this xpTransaction id,
     * no additional balance change occurs.
     */
    @Transactional
    public int awardForXpTransaction(User user, XpTransaction xpTransaction) {
        if (xpTransaction == null || xpTransaction.getAmount() <= 0) {
            return 0;
        }
        int credits = (xpTransaction.getAmount() * CREDIT_FACTOR_NUMERATOR) / CREDIT_FACTOR_DENOMINATOR;
        if (credits <= 0) {
            return 0;
        }
        UUID refId = xpTransaction.getId();
        if (refId != null
                && creditLedgerRepository.countByUserIdAndReferenceTypeAndReferenceId(
                        user.getId(), "XP_TRANSACTION", refId) > 0) {
            log.debug("CREDIT_EARN_DUPLICATE user={} xpTx={}", user.getId(), refId);
            return 0;
        }
        UserCredit uc = getOrCreateWithLock(user);
        uc.setBalance(uc.getBalance() + credits);
        userCreditRepository.save(uc);

        CreditLedger row = new CreditLedger();
        row.setUser(user);
        row.setAmount(credits);
        row.setReason("CREDIT_EARNED");
        row.setReferenceType("XP_TRANSACTION");
        row.setReferenceId(refId);
        row.setDescription("Credits from XP: " + xpTransaction.getEventType().name());
        creditLedgerRepository.save(row);
        log.debug("CREDIT_EARNED user={} credits={} xp={}", user.getId(), credits, xpTransaction.getAmount());
        return credits;
    }

    /**
     * Spend credits atomically (purchase). Must be called within the caller's
     * transaction that also creates user_avatars ownership. Uses pessimistic
     * lock on user_credits, verifies balance, deducts once.
     */
    @Transactional
    public void spend(User user, int cost, UUID avatarId) {
        if (cost <= 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Invalid credit cost");
        }
        UserCredit uc = getOrCreateWithLock(user);
        if (uc.getBalance() < cost) {
            throw new ApiException(ErrorCode.INSUFFICIENT_CREDITS.getHttpStatus(),
                    ErrorCode.INSUFFICIENT_CREDITS.name(),
                    "Insufficient credits");
        }
        uc.setBalance(uc.getBalance() - cost);
        userCreditRepository.save(uc);

        CreditLedger row = new CreditLedger();
        row.setUser(user);
        row.setAmount(-cost);
        row.setReason("CREDIT_SPENT");
        row.setReferenceType("AVATAR_PURCHASE");
        row.setReferenceId(avatarId);
        row.setDescription("Avatar purchase: " + avatarId);
        creditLedgerRepository.save(row);
        log.info("CREDIT_SPENT user={} cost={} avatar={}", user.getId(), cost, avatarId);
    }

    @Transactional(readOnly = true)
    public int balance(UUID userId) {
        return userCreditRepository.findByUserId(userId)
                .map(UserCredit::getBalance)
                .orElse(0);
    }

    public static int creditsForXp(int xpAmount) {
        if (xpAmount <= 0) {
            return 0;
        }
        return (xpAmount * CREDIT_FACTOR_NUMERATOR) / CREDIT_FACTOR_DENOMINATOR;
    }

    private UserCredit getOrCreateWithLock(User user) {
        return userCreditRepository.findWithLock(user.getId())
                .orElseGet(() -> {
                    UserCredit created = new UserCredit();
                    created.setUser(user);
                    created.setBalance(0);
                    try {
                        return userCreditRepository.saveAndFlush(created);
                    } catch (org.springframework.dao.DataIntegrityViolationException raced) {
                        // concurrent creator won — reload under lock
                        return userCreditRepository.findWithLock(user.getId())
                                .orElseThrow(() -> new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                                        ErrorCode.INTERNAL_ERROR.name(), "User credit race could not be resolved"));
                    }
                });
    }
}
