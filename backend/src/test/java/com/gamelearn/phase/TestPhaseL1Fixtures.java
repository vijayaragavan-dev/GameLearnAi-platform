package com.gamelearn.phase;

import java.math.BigDecimal;
import java.util.UUID;

import com.gamelearn.entity.Avatar;
import com.gamelearn.entity.User;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.entity.enums.XpEventType;
import com.gamelearn.persistence.PersistenceTestFixtures;

public final class TestPhaseL1Fixtures {
    private TestPhaseL1Fixtures() {}
    public static Avatar avatar(String code, String rarity, Integer cost, String requirementJson, boolean active) {
        Avatar a = new Avatar();
        a.setCode(code + "-" + UUID.randomUUID());
        a.setDisplayName(code);
        a.setDescription(code + " description");
        a.setRarity(rarity);
        a.setAssetKey("characters/" + code.toLowerCase());
        a.setRequirementJson(requirementJson);
        a.setCreditCost(cost);
        a.setActive(active);
        a.setDisplayOrder(0);
        return a;
    }
    public static XpTransaction xp(User user, int amount) {
        XpTransaction t = new XpTransaction();
        t.setUser(user);
        t.setAmount(amount);
        t.setEventType(XpEventType.QUIZ_COMPLETED);
        t.setReferenceType("QUIZ_ATTEMPT");
        t.setReferenceId(UUID.randomUUID());
        t.setDescription("test xp");
        return t;
    }
}
