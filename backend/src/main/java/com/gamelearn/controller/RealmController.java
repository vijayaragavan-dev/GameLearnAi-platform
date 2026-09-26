package com.gamelearn.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.dto.RealmResponse;
import com.gamelearn.dto.SubjectResponse;
import com.gamelearn.service.RealmService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * REALM-001: learning-realm catalogue and realm-scoped subject listing.
 *
 * <p>Read-only. Follows the existing product security policy (all
 * {@code /api/v1/**} endpoints except auth/health/docs require a
 * bearer token) — no security configuration change was needed.
 */
@RestController
@RequestMapping("/api/v1/realms")
@Tag(name = "Realms", description = "Learning realm catalogue")
@SecurityRequirement(name = "bearerAuth")
public class RealmController {

    private final RealmService realmService;

    public RealmController(RealmService realmService) {
        this.realmService = realmService;
    }

    @Operation(summary = "List active realms",
            description = "Returns all active realms ordered by display order.")
    @GetMapping
    public List<RealmResponse> listRealms() {
        return realmService.listActiveRealms();
    }

    @Operation(summary = "Get a single active realm by key",
            description = "Realm keys are stable machine-readable identifiers. Unknown or inactive keys return 404.")
    @GetMapping("/{realmKey}")
    public RealmResponse getRealm(@PathVariable String realmKey) {
        return toResponse(realmService.requireActiveRealm(realmKey));
    }

    @Operation(summary = "List active subjects of a realm",
            description = "Returns active subjects explicitly associated with the realm, ordered by display order.")
    @GetMapping("/{realmKey}/subjects")
    public List<SubjectResponse> realmSubjects(@PathVariable String realmKey) {
        return realmService.subjectsForRealm(realmKey);
    }

    private RealmResponse toResponse(com.gamelearn.entity.Realm realm) {
        return new RealmResponse(realm.getId(), realm.getRealmKey(), realm.getName(),
                realm.getDescription(), realm.getIconKey(), realm.isActive(),
                realm.getDisplayOrder());
    }
}
