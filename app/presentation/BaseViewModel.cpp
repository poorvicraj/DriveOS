#include "BaseViewModel.hpp"

namespace driveos::presentation {

BaseViewModel::BaseViewModel(QObject* parent)
    : QObject(parent)
    , m_isRestricted(false)
    , m_isHealthy(true)
{
}

void BaseViewModel::setRestricted(bool restricted, const QString& reason) {
    if (m_isRestricted != restricted || m_restrictionMessage != reason) {
        m_isRestricted = restricted;
        m_restrictionMessage = reason;
        emit isRestrictedChanged(m_isRestricted);
        emit restrictionMessageChanged(m_restrictionMessage);
    }
}

void BaseViewModel::setHealthy(bool healthy) {
    if (m_isHealthy != healthy) {
        m_isHealthy = healthy;
        emit isHealthyChanged(m_isHealthy);
    }
}

} // namespace driveos::presentation
