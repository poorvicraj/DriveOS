#pragma once

#include "VehicleState.hpp"
#include "VehicleStateManager.hpp"
#include <string>

namespace driveos::domain {

/**
 * @brief Categorization of UI touch interactions subject to driver distraction rules.
 */
enum class InteractionCategory : uint8_t {
    PRIMARY_NAVIGATION = 0, // Dock tab switching (Home, Media, Climate, Vehicle, Navigation)
    BASIC_HVAC,             // Quick temperature bump, fan adjust
    BASIC_MEDIA,            // Play/pause, track skip, volume adjust
    DEEP_SETTINGS,          // Vehicle closure toggles, lighting config, drive dynamics
    NUMERIC_OR_TEXT_INPUT,  // Diagnostic entry, address search
    MODAL_INSPECTION        // Diagnostic detail modals, full logs
};

/**
 * @brief Safety policy outcome for a requested interaction.
 */
struct SafetyEvaluation {
    bool isAllowed{true};
    std::string restrictionReason;
};

/**
 * @brief Driver Distraction & Safety-Aware UX Policy Engine.
 * 
 * Centralizes vehicle state queries and driver distraction heuristics.
 * Evaluates whether UI touch interactions, configuration settings,
 * and inputs are permitted based on operational state and motion.
 * 
 * NOTE: This is a SOFTWARE UX POLICY for automotive HMI distraction mitigation.
 * It is a production prototype and does NOT claim formal ISO 26262 functional safety compliance.
 */
class SafetyPolicy {
public:
    explicit SafetyPolicy(const VehicleStateManager* stateManager = nullptr)
        : m_stateManager(stateManager) {}
    virtual ~SafetyPolicy() = default;

    void setStateManager(const VehicleStateManager* stateManager) noexcept {
        m_stateManager = stateManager;
    }

    /**
     * @brief Checks if the vehicle is currently considered in motion.
     * @param state Canonical vehicle state.
     * @return true if speed exceeds 0.1 km/h or gear is in DRIVE/REVERSE.
     */
    [[nodiscard]] static bool isInMotion(const VehicleState& state) noexcept {
        return (state.speed > 0.1f) ||
               (state.gear == Gear::DRIVE) ||
               (state.gear == Gear::REVERSE);
    }

    // -------------------------------------------------------------------------
    // Core Safety Policy Methods (Prompt 11 Requirements)
    // -------------------------------------------------------------------------

    /**
     * @brief Determines whether vehicle configuration (drive mode, closures, lighting) is allowed.
     * Restricts configuration when driving in motion or when in FAULT state.
     */
    [[nodiscard]] bool isVehicleConfigurationAllowed(const VehicleState& state) const noexcept {
        return !isInMotion(state) && (state.operationalState != OperationalState::FAULT);
    }

    [[nodiscard]] bool isVehicleConfigurationAllowed() const noexcept {
        if (m_stateManager) {
            return isVehicleConfigurationAllowed(m_stateManager->getVehicleState());
        }
        return true;
    }

    /**
     * @brief Determines whether essential climate controls (temperature bump, fan, AC) are allowed.
     * Always allowed during DRIVING and PARKED to preserve cabin comfort.
     */
    [[nodiscard]] bool isEssentialClimateControlAllowed(const VehicleState& /*state*/) const noexcept {
        return true;
    }

    [[nodiscard]] bool isEssentialClimateControlAllowed() const noexcept {
        return true;
    }

    /**
     * @brief Determines whether basic media controls (play/pause, skip, volume) are allowed.
     * Always allowed during DRIVING and PARKED to minimize glance time.
     */
    [[nodiscard]] bool isMediaControlAllowed(const VehicleState& /*state*/) const noexcept {
        return true;
    }

    [[nodiscard]] bool isMediaControlAllowed() const noexcept {
        return true;
    }

    /**
     * @brief Determines whether glanceable navigation interactions are allowed.
     * Essential navigation views and maneuvers are allowed in motion.
     */
    [[nodiscard]] bool isNavigationInteractionAllowed(const VehicleState& /*state*/) const noexcept {
        return true;
    }

    [[nodiscard]] bool isNavigationInteractionAllowed() const noexcept {
        return true;
    }

    /**
     * @brief Determines whether vehicle glanceable status display is allowed.
     */
    [[nodiscard]] bool isVehicleStatusAllowed() const noexcept {
        return true;
    }

    /**
     * @brief Standard visual explanation text for restricted driving interactions.
     */
    static constexpr const char* RESTRICTION_MESSAGE = "Unavailable while driving";
    static constexpr const char* RESTRICTION_ICON = "🔒";

    [[nodiscard]] std::string getRestrictionReason() const {
        return RESTRICTION_MESSAGE;
    }

    [[nodiscard]] std::string getRestrictionIcon() const {
        return RESTRICTION_ICON;
    }

    /**
     * @brief Evaluates whether a specific interaction category is permitted.
     * @param category UI interaction type.
     * @param state Canonical vehicle state.
     * @return SafetyEvaluation containing permission flag and rationale.
     */
    [[nodiscard]] SafetyEvaluation evaluateInteraction(InteractionCategory category,
                                                       const VehicleState& state) const {
        if (!isInMotion(state)) {
            if (state.operationalState == OperationalState::FAULT && category == InteractionCategory::DEEP_SETTINGS) {
                return {false, "Unavailable while system is in FAULT state"};
            }
            return {true, ""};
        }

        // Vehicle is in motion: enforce driver distraction restrictions
        switch (category) {
        case InteractionCategory::PRIMARY_NAVIGATION:
        case InteractionCategory::BASIC_HVAC:
        case InteractionCategory::BASIC_MEDIA:
            return {true, ""};

        case InteractionCategory::DEEP_SETTINGS:
            return {false, RESTRICTION_MESSAGE};

        case InteractionCategory::NUMERIC_OR_TEXT_INPUT:
            return {false, "Unavailable while driving — Text input locked in motion"};

        case InteractionCategory::MODAL_INSPECTION:
            return {false, "Unavailable while driving — Diagnostics locked in motion"};
        }

        return {true, ""};
    }

private:
    const VehicleStateManager* m_stateManager{nullptr};
};

} // namespace driveos::domain
