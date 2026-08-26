package com.gamelearn.adaptive;

/**
 * Immutable business constants from GameLearn_AI_Adaptive_Engine_Specification.md
 * v1.0.0 (APPROVED), section 23. Changing any value requires a specification
 * version bump — these are business rules, not runtime configuration.
 */
public final class AdaptiveConstants {

    /** Specification version implemented by this package. */
    public static final String SPEC_VERSION = "1.0.0";

    public static final java.math.BigDecimal MASTERY_MIN = new java.math.BigDecimal("0.00");
    public static final java.math.BigDecimal MASTERY_MAX = new java.math.BigDecimal("100.00");

    /** Evidence-weight divisor cap: weight = 1 / min(n, WEIGHT_DIVISOR_CAP). */
    public static final int WEIGHT_DIVISOR_CAP = 5;

    public static final java.math.BigDecimal THRESHOLD_BEGINNER_MAX = new java.math.BigDecimal("40.00");
    public static final java.math.BigDecimal THRESHOLD_DEVELOPING_MAX = new java.math.BigDecimal("70.00");
    public static final java.math.BigDecimal THRESHOLD_PROFICIENT_MAX = new java.math.BigDecimal("90.00");

    /** Meaningful last-attempt accuracy change (percentage points). */
    public static final java.math.BigDecimal TREND_DELTA = new java.math.BigDecimal("5.00");

    /** Recent excellence threshold for the strong-performance rule (R3). */
    public static final java.math.BigDecimal STRONG_ACCURACY = new java.math.BigDecimal("85.00");

    public static final int SCALE = 2;

    private AdaptiveConstants() {
    }
}
