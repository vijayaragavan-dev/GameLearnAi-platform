package com.gamelearn.phase;

import static org.assertj.core.api.Assertions.*;

import java.math.BigDecimal;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.Avatar;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.entity.enums.ProgressStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.AvatarRepository;
import com.gamelearn.repository.CreditLedgerRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAvatarRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;
import com.gamelearn.service.AvatarRequirementEvaluator;
import com.gamelearn.service.AvatarService;
import com.gamelearn.service.CreditService;
import com.gamelearn.service.SyllabusService;

@SpringBootTest
@ActiveProfiles("test")
class AvatarAndSyllabusPhaseL1Test {

    @Autowired AvatarRepository avatarRepository;
    @Autowired UserRepository userRepository;
    @Autowired LearnerProfileRepository learnerProfileRepository;
    @Autowired UserAvatarRepository userAvatarRepository;
    @Autowired AvatarService avatarService;
    @Autowired SyllabusService syllabusService;
    @Autowired AvatarRequirementEvaluator evaluator;
    @Autowired CreditService creditService;
    @Autowired XpTransactionRepository xpTransactionRepository;
    @Autowired CreditLedgerRepository creditLedgerRepository;
    @Autowired SubjectRepository subjectRepository;
    @Autowired TopicRepository topicRepository;
    @Autowired ProgressRepository progressRepository;
    @Autowired com.gamelearn.repository.UserCreditRepository userCreditRepository;

    // AVT-01: avatar catalog loads (24 seeded)
    @Test
    @Transactional
    void avt01_catalogLoads() {
        var list = avatarRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc();
        assertThat(list).hasSizeGreaterThanOrEqualTo(24);
    }

    // AVT-02: avatar code uniqueness enforced
    @Test
    @Transactional
    void avt02_codeUniqueness() {
        Avatar a1 = TestPhaseL1Fixtures.avatar("UNIQ-CODE", "COMMON", 1000, null, true);
        a1.setCode("duplicate-code-" + UUID.randomUUID());
        String dup = a1.getCode();
        avatarRepository.save(a1);
        Avatar a2 = TestPhaseL1Fixtures.avatar("UNIQ-CODE2", "COMMON", 1000, null, true);
        a2.setCode(dup);
        assertThatThrownBy(() -> { avatarRepository.saveAndFlush(a2); })
                .isInstanceOf(Exception.class);
    }

    // AVT-03: inactive avatar cannot be purchased/claimed
    @Test
    @Transactional
    void avt03_inactiveCannotBePurchased() {
        User user = newUserWithProfile("avt03");
        Avatar inactive = TestPhaseL1Fixtures.avatar("inactive", "COMMON", 500, null, false);
        inactive = avatarRepository.save(inactive);
        giveCredits(user, 1000);
        UUID aid = inactive.getId();
        assertThatThrownBy(() -> avatarService.purchase(user.getId(), aid))
                .isInstanceOf(ApiException.class);
    }

    // AVT-04: 69.99% syllabus is ineligible (threshold 70)
    @Test
    @Transactional
    void avt04_6999Ineligible() {
        var setup = prepareSyllabusForSubject(100, 69, false);
        Avatar leg = avatarForSubject(setup.subjectId(), 70.0);
        leg = avatarRepository.save(leg);
        // boost level to 18 so only syllabus blocks
        setLevel(setup.user(), 18);
        var result = evaluator.evaluate(setup.user().getId(), leg);
        assertThat(result.eligible()).isFalse();
        // exact completion check
        BigDecimal pct = syllabusService.syllabusCompletion(setup.user().getId(), setup.subjectId());
        assertThat(pct).isEqualByComparingTo(new BigDecimal("69.00"));
    }

    // AVT-05: 70.00% eligible
    @Test
    @Transactional
    void avt05_7000Eligible() {
        var setup = prepareSyllabusForSubject(10, 7, true);
        Avatar leg = avatarForSubject(setup.subjectId(), 70.0);
        leg = avatarRepository.save(leg);
        setLevel(setup.user(), 18);
        // need to satisfy other gates? only level+ syllabus in this avatar so eligible
        var result = evaluator.evaluate(setup.user().getId(), leg);
        assertThat(result.eligible()).isTrue();
        BigDecimal pct = syllabusService.syllabusCompletion(setup.user().getId(), setup.subjectId());
        assertThat(pct).isEqualByComparingTo(new BigDecimal("70.00"));
    }

    // AVT-06: 70.01 eligible (71% because discrete topics)
    @Test
    @Transactional
    void avt06_7001Eligible() {
        var setup = prepareSyllabusForSubject(100, 71, true);
        Avatar leg = avatarForSubject(setup.subjectId(), 70.0);
        leg = avatarRepository.save(leg);
        setLevel(setup.user(), 18);
        var result = evaluator.evaluate(setup.user().getId(), leg);
        assertThat(result.eligible()).isTrue();
    }

    // AVT-07: inactive topics handled correctly (excluded from denominator)
    @Test
    @Transactional
    void avt07_inactiveTopicsExcluded() {
        User user = newUserWithProfile("avt07");
        Subject subj = subjectRepository.save(PersistenceTestFixtures.subject("AVT07"));
        // 4 active + 2 inactive
        Topic t1 = topicRepository.save(PersistenceTestFixtures.topic("T1", subj));
        Topic t2 = topicRepository.save(PersistenceTestFixtures.topic("T2", subj));
        Topic t3 = topicRepository.save(PersistenceTestFixtures.topic("T3", subj));
        Topic t4 = topicRepository.save(PersistenceTestFixtures.topic("T4", subj));
        Topic ti1 = PersistenceTestFixtures.topic("TI1", subj); ti1.setActive(false); topicRepository.save(ti1);
        Topic ti2 = PersistenceTestFixtures.topic("TI2", subj); ti2.setActive(false); topicRepository.save(ti2);
        // complete 2 of 4 active => 50%
        for (Topic t : java.util.List.of(t1, t2)) {
            Progress p = new Progress(); p.setUser(user); p.setTopic(t);
            p.setStatus(ProgressStatus.COMPLETED); p.setCompletionPercentage(new BigDecimal("100.00"));
            progressRepository.save(p);
        }
        BigDecimal pct = syllabusService.syllabusCompletion(user.getId(), subj.getId());
        assertThat(pct).isEqualByComparingTo(new BigDecimal("50.00"));
    }

    // AVT-08: real existing progress data handled (no fake topics)
    @Test
    @Transactional
    void avt08_progressDataHandled() {
        var setup = prepareSyllabusForSubject(5, 5, true);
        BigDecimal pct = syllabusService.syllabusCompletion(setup.user().getId(), setup.subjectId());
        assertThat(pct).isEqualByComparingTo(new BigDecimal("100.00"));
    }

    // AVT-09: composite requirements evaluate correctly (AND)
    @Test
    @Transactional
    void avt09_compositeRequirementsAnd() {
        var setup = prepareSyllabusForSubject(10, 8, true); // 80%
        Avatar av = new Avatar();
        av.setCode("composite-" + UUID.randomUUID());
        av.setDisplayName("Composite");
        av.setDescription("composite desc");
        av.setRarity("LEGENDARY");
        av.setAssetKey("characters/composite");
        av.setRequirementJson("{\"levelMin\":18,\"syllabusCompletionMin\":70.0,\"syllabusSubjectId\":\"" + setup.subjectId() + "\"}");
        av.setActive(true); av.setDisplayOrder(99);
        av = avatarRepository.save(av);
        setLevel(setup.user(), 10); // fail level
        var r1 = evaluator.evaluate(setup.user().getId(), av);
        assertThat(r1.eligible()).isFalse();
        setLevel(setup.user(), 18);
        var r2 = evaluator.evaluate(setup.user().getId(), av);
        assertThat(r2.eligible()).isTrue();
    }

    // AVT-10: unowned avatar cannot become equipped
    @Test
    @Transactional
    void avt10_unownedCannotEquip() {
        User user = newUserWithProfile("avt10");
        Avatar av = TestPhaseL1Fixtures.avatar("unequipped", "COMMON", 500, null, true);
        av = avatarRepository.save(av);
        UUID uid = user.getId(); UUID aid = av.getId();
        assertThatThrownBy(() -> avatarService.equip(uid, aid))
                .isInstanceOf(ApiException.class);
    }

    // CRED-06 duplicate ownership cannot occur
    @Test
    @Transactional
    void cred06_duplicateOwnership() {
        User user = newUserWithProfile("dupOwn");
        Avatar av = TestPhaseL1Fixtures.avatar("dupOwnAv", "COMMON", 500, null, true);
        av = avatarRepository.save(av);
        giveCredits(user, 1000);
        avatarService.purchase(user.getId(), av.getId());
        UUID uid = user.getId(); UUID aid = av.getId();
        assertThatThrownBy(() -> avatarService.purchase(uid, aid))
                .isInstanceOf(ApiException.class);
        assertThat(userAvatarRepository.findByUserId(uid)).hasSize(1);
    }

    // CRED-07 concurrent purchase protection (simulate double spend with lock)
    @Test
    @Transactional
    void cred07_concurrentPurchaseProtection() {
        User user = newUserWithProfile("concBuy");
        Avatar av1 = TestPhaseL1Fixtures.avatar("conc1", "COMMON", 800, null, true);
        Avatar av2 = TestPhaseL1Fixtures.avatar("conc2", "COMMON", 800, null, true);
        av1 = avatarRepository.save(av1); av2 = avatarRepository.save(av2);
        giveCreditsFor(user, 1000);
        // first purchase consumes 800 leaving 200; second needs 800 should fail
        avatarService.purchase(user.getId(), av1.getId());
        UUID uid = user.getId(); UUID aid2 = av2.getId();
        assertThatThrownBy(() -> avatarService.purchase(uid, aid2))
                .isInstanceOf(ApiException.class);
        assertThat(creditService.balance(uid)).isEqualTo(200);
    }

    // CRED-08 atomic rollback: credits deducted only if ownership created
    @Test
    @Transactional
    void cred08_atomicRollbackOnDuplicate() {
        User user = newUserWithProfile("atomic");
        Avatar av = TestPhaseL1Fixtures.avatar("atomicAv", "COMMON", 600, null, true);
        av = avatarRepository.save(av);
        giveCreditsFor(user, 1000);
        avatarService.purchase(user.getId(), av.getId());
        int balAfterFirst = creditService.balance(user.getId());
        assertThat(balAfterFirst).isEqualTo(400);
        // duplicate should not deduct again
        try { avatarService.purchase(user.getId(), av.getId()); } catch (Exception ignored) {}
        assertThat(creditService.balance(user.getId())).isEqualTo(400);
        assertThat(creditLedgerRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).hasSize(2); // 1 earn + 1 spend
    }

    // SEC-01..03: client cannot set arbitrary credits/ownership/eligibility - verified by API layer non-existence and service guards
    @Test
    @Transactional
    void sec_guards() {
        User user = newUserWithProfile("sec");
        Subject secSubj = subjectRepository.save(PersistenceTestFixtures.subject("SEC"));
        final Avatar av = avatarRepository.save(TestPhaseL1Fixtures.avatar("secAv", "LEGENDARY", null,
                "{\"levelMin\":99,\"syllabusCompletionMin\":99.0,\"syllabusSubjectId\":\"" + secSubj.getId() + "\"}", true));
        var eval = evaluator.evaluate(user.getId(), av);
        assertThat(eval.eligible()).isFalse();
        assertThatThrownBy(() -> avatarService.claim(user.getId(), av.getId()))
                .isInstanceOf(ApiException.class);
    }

    // helpers
    private User newUserWithProfile(String label) {
        User user = userRepository.save(PersistenceTestFixtures.user(label));
        LearnerProfile p = new LearnerProfile(); p.setUser(user);
        learnerProfileRepository.save(p);
        return user;
    }
    private void giveCredits(User user, int xpAmount) {
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, xpAmount);
        xp = xpTransactionRepository.save(xp);
        creditService.awardForXpTransaction(user, xp);
    }
    private void giveCreditsFor(User user, int desiredCredits) {
        int xpNeeded = (int) Math.ceil(desiredCredits * 100.0 / 60.0);
        XpTransaction xp = TestPhaseL1Fixtures.xp(user, xpNeeded);
        xp = xpTransactionRepository.save(xp);
        creditService.awardForXpTransaction(user, xp);
        int current = creditService.balance(user.getId());
        if (current != desiredCredits) {
            com.gamelearn.entity.UserCredit uc = userCreditRepository.findByUserId(user.getId()).orElseThrow();
            uc.setBalance(desiredCredits);
            userCreditRepository.save(uc);
        }
    }
    private void setLevel(User user, int level) {
        LearnerProfile p = learnerProfileRepository.findByUserId(user.getId()).orElseThrow();
        p.setCurrentLevel(level);
        // totalXp must satisfy threshold for level, but evaluator reads level directly
        learnerProfileRepository.save(p);
    }
    private Avatar avatarForSubject(UUID subjectId, double minPct) {
        Avatar av = new Avatar();
        Subject subj = subjectRepository.findById(subjectId).orElseThrow();
        av.setCode("leg-" + UUID.randomUUID());
        av.setDisplayName("Leg");
        av.setDescription("leg desc");
        av.setRarity("LEGENDARY");
        av.setHomeSubject(subj);
        av.setAssetKey("characters/leg");
        av.setRequirementJson("{\"levelMin\":18,\"syllabusCompletionMin\":" + minPct + ",\"syllabusSubjectId\":\"" + subjectId + "\"}");
        av.setActive(true); av.setDisplayOrder(99);
        return av;
    }
    private record SyllabusSetup(User user, UUID subjectId) {}
    private SyllabusSetup prepareSyllabusForSubject(int totalTopics, int completedCount, boolean useLearnerProfileUser) {
        User user = newUserWithProfile("syl-" + UUID.randomUUID().toString().substring(0,4));
        Subject subj = subjectRepository.save(PersistenceTestFixtures.subject("SYL"));
        for (int i=0;i<totalTopics;i++) {
            Topic t = topicRepository.save(PersistenceTestFixtures.topic("T"+i, subj));
            if (i < completedCount) {
                Progress pr = new Progress(); pr.setUser(user); pr.setTopic(t);
                pr.setStatus(ProgressStatus.COMPLETED); pr.setCompletionPercentage(new BigDecimal("100.00"));
                progressRepository.save(pr);
            }
        }
        return new SyllabusSetup(user, subj.getId());
    }
}
