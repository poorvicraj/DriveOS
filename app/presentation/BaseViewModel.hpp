#pragma once

#include <QObject>
#include <QString>

namespace driveos::presentation {

/**
 * @brief Base class for all Presentation ViewModels in the DriveOS MVVM architecture.
 * 
 * Provides common property bindings for UI safety gating, degraded communication
 * status notifications, and user error reporting.
 */
class BaseViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRestricted READ isRestricted NOTIFY isRestrictedChanged)
    Q_PROPERTY(QString restrictionMessage READ restrictionMessage NOTIFY restrictionMessageChanged)
    Q_PROPERTY(bool isHealthy READ isHealthy NOTIFY isHealthyChanged)

public:
    explicit BaseViewModel(QObject* parent = nullptr);
    ~BaseViewModel() override = default;

    [[nodiscard]] bool isRestricted() const noexcept { return m_isRestricted; }
    [[nodiscard]] QString restrictionMessage() const { return m_restrictionMessage; }
    [[nodiscard]] bool isHealthy() const noexcept { return m_isHealthy; }

signals:
    void isRestrictedChanged(bool restricted);
    void restrictionMessageChanged(const QString& message);
    void isHealthyChanged(bool healthy);
    void userNotificationRequested(const QString& title, const QString& message);

protected:
    void setRestricted(bool restricted, const QString& reason = QString());
    void setHealthy(bool healthy);

private:
    bool m_isRestricted{false};
    QString m_restrictionMessage;
    bool m_isHealthy{true};
};

} // namespace driveos::presentation
