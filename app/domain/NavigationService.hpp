#pragma once

#include "VehicleState.hpp"
#include "SafetyPolicy.hpp"
#include <string>
#include <vector>
#include <functional>
#include <algorithm>

namespace driveos::domain {

/**
 * @brief Representation of a navigation point of interest / destination.
 */
struct NavigationDestination {
    std::string id;
    std::string name;
    std::string category;      // "Landmark", "Favorite", "Work", "Education", "Recent"
    std::string icon;
    float distanceKm{8.4f};
    int etaMinutes{18};
    std::string maneuverText;
    std::string turnIcon;       // "↱", "↰", "↑", "↖", "↗"
    float destX{0.72f};         // Normalized canvas coordinate
    float destY{0.28f};
};

/**
 * @brief Application domain service managing simulated automotive navigation telemetry.
 * 
 * Provides mock destinations, route status, ETA, distance, and turn-by-turn maneuvers
 * without integrating proprietary external map engines.
 */
class NavigationService {
public:
    using NavigationChangedCallback = std::function<void()>;

    explicit NavigationService(SafetyPolicy* safetyPolicy = nullptr)
        : m_safetyPolicy(safetyPolicy)
    {
        initDestinations();
    }

    virtual ~NavigationService() = default;

    [[nodiscard]] const std::vector<NavigationDestination>& getDestinations() const noexcept {
        return m_destinations;
    }

    [[nodiscard]] const NavigationDestination& getActiveDestination() const noexcept {
        return m_destinations[m_activeDestinationIndex];
    }

    [[nodiscard]] size_t getActiveDestinationIndex() const noexcept {
        return m_activeDestinationIndex;
    }

    [[nodiscard]] bool isNavigating() const noexcept {
        return m_isNavigating;
    }

    virtual void selectDestinationIndex(size_t index) {
        if (index < m_destinations.size()) {
            m_activeDestinationIndex = index;
            notifyObservers();
        }
    }

    virtual void startNavigation() {
        m_isNavigating = true;
        notifyObservers();
    }

    virtual void stopNavigation() {
        m_isNavigating = false;
        notifyObservers();
    }

    virtual void toggleNavigation() {
        m_isNavigating = !m_isNavigating;
        notifyObservers();
    }

    virtual void registerObserver(NavigationChangedCallback callback) {
        m_observers.push_back(std::move(callback));
    }

private:
    void initDestinations() {
        m_destinations = {
            {
                "palace",
                "Mysuru Palace",
                "Landmark",
                "🏰",
                8.4f,
                18,
                "In 450 m, turn right onto Palace Road",
                "↱",
                0.74f,
                0.26f
            },
            {
                "home",
                "Home (North District)",
                "Favorite",
                "🏠",
                4.2f,
                11,
                "In 1.2 km, keep left on Outer Ring Road",
                "↖",
                0.28f,
                0.35f
            },
            {
                "work",
                "Cyber Park (Infosys Campus)",
                "Work",
                "🏢",
                16.8f,
                28,
                "In 800 m, take flyover towards Hebbal",
                "↗",
                0.80f,
                0.68f
            },
            {
                "tech_university",
                "Technology University Campus",
                "Education",
                "🏫",
                6.5f,
                14,
                "In 300 m, turn left onto Campus Boulevard",
                "↰",
                0.34f,
                0.72f
            },
            {
                "chamundi",
                "Chamundi Hill Viewpoint",
                "Recent",
                "⛰️",
                13.2f,
                24,
                "In 2.1 km, sharp right on Hill Road",
                "↻",
                0.65f,
                0.82f
            }
        };
        m_activeDestinationIndex = 0;
    }

    void notifyObservers() {
        for (const auto& obs : m_observers) {
            if (obs) obs();
        }
    }

    SafetyPolicy* m_safetyPolicy{nullptr};
    std::vector<NavigationDestination> m_destinations;
    size_t m_activeDestinationIndex{0};
    bool m_isNavigating{true}; // Default to active route for rich first impression
    std::vector<NavigationChangedCallback> m_observers;
};

} // namespace driveos::domain
