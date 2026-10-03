#pragma once

#include <QList>
#include <QObject>
#include <QString>

namespace driveos::presentation {

/**
 * @brief Centralized navigation controller for the DriveOS digital cockpit.
 * 
 * Enforces a single source of truth for application routing across the persistent
 * dock and screen transitions, supporting both forward and back navigation.
 */
class NavigationController : public QObject {
    Q_OBJECT
    Q_PROPERTY(Screen currentScreen READ currentScreen WRITE navigateTo NOTIFY currentScreenChanged)
    Q_PROPERTY(QString currentScreenName READ currentScreenName NOTIFY currentScreenChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY canGoBackChanged)

public:
    enum class Screen {
        Home = 0,
        Media,
        Climate,
        Vehicle,
        Navigation
    };
    Q_ENUM(Screen)

    explicit NavigationController(QObject* parent = nullptr);
    ~NavigationController() override = default;

    [[nodiscard]] Screen currentScreen() const noexcept { return m_currentScreen; }
    [[nodiscard]] QString currentScreenName() const;
    [[nodiscard]] bool canGoBack() const noexcept { return !m_history.isEmpty(); }

    Q_INVOKABLE void navigateTo(Screen screen);
    Q_INVOKABLE void navigateToName(const QString& screenName);
    Q_INVOKABLE void goBack();

signals:
    void currentScreenChanged(Screen screen);
    void canGoBackChanged(bool canGoBack);

private:
    Screen m_currentScreen{Screen::Home};
    QList<Screen> m_history;
};

} // namespace driveos::presentation
