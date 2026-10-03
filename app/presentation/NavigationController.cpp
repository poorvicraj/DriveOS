#include "NavigationController.hpp"

namespace driveos::presentation {

NavigationController::NavigationController(QObject* parent)
    : QObject(parent)
    , m_currentScreen(Screen::Home)
{
}

QString NavigationController::currentScreenName() const {
    switch (m_currentScreen) {
    case Screen::Home:       return QStringLiteral("Home");
    case Screen::Media:      return QStringLiteral("Media");
    case Screen::Climate:    return QStringLiteral("Climate");
    case Screen::Vehicle:    return QStringLiteral("Vehicle");
    case Screen::Navigation: return QStringLiteral("Navigation");
    }
    return QStringLiteral("Home");
}

void NavigationController::navigateTo(Screen screen) {
    if (m_currentScreen != screen) {
        m_history.append(m_currentScreen);
        if (m_history.size() > 30) {
            m_history.removeFirst();
        }
        m_currentScreen = screen;
        emit currentScreenChanged(m_currentScreen);
        emit canGoBackChanged(canGoBack());
    }
}

void NavigationController::navigateToName(const QString& screenName) {
    if (screenName == QLatin1String("Home") || screenName == QLatin1String("HomeScreen")) {
        navigateTo(Screen::Home);
    } else if (screenName == QLatin1String("Media") || screenName == QLatin1String("MediaScreen")) {
        navigateTo(Screen::Media);
    } else if (screenName == QLatin1String("Climate") || screenName == QLatin1String("ClimateScreen")) {
        navigateTo(Screen::Climate);
    } else if (screenName == QLatin1String("Vehicle") || screenName == QLatin1String("VehicleScreen")) {
        navigateTo(Screen::Vehicle);
    } else if (screenName == QLatin1String("Navigation") || screenName == QLatin1String("NavigationScreen")) {
        navigateTo(Screen::Navigation);
    }
}

void NavigationController::goBack() {
    if (!m_history.isEmpty()) {
        m_currentScreen = m_history.takeLast();
        emit currentScreenChanged(m_currentScreen);
        emit canGoBackChanged(canGoBack());
    }
}

} // namespace driveos::presentation
