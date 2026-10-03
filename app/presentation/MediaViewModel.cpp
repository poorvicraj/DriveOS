#include "MediaViewModel.hpp"

namespace driveos::presentation {

MediaViewModel::MediaViewModel(domain::MediaService* mediaService, QObject* parent)
    : BaseViewModel(parent)
    , m_mediaService(mediaService)
{
    if (m_mediaService) {
        m_mediaService->registerTrackCallback([this](const domain::MediaTrack&) {
            emit trackChanged();
            emit progressChanged();
            updateQueueModel();
        });

        m_mediaService->registerPlaybackCallback([this](domain::PlaybackState) {
            emit playbackStateChanged();
        });

        m_mediaService->registerVolumeCallback([this](int) {
            emit volumeChanged();
        });

        updateQueueModel();
    }

    // Playback progression timer (1s ticks)
    m_progressTimer = new QTimer(this);
    connect(m_progressTimer, &QTimer::timeout, this, [this]() {
        if (!m_mediaService || !m_mediaService->hasMedia()) return;

        if (m_mediaService->getPlaybackState() == domain::PlaybackState::PLAYING) {
            auto track = m_mediaService->getCurrentTrack();
            track.elapsedSec++;
            if (track.elapsedSec >= track.durationSec) {
                m_mediaService->nextTrack();
            } else {
                m_mediaService->seekTo(track.elapsedSec);
                emit progressChanged();
            }
        }
    });
    m_progressTimer->start(1000);
}

QString MediaViewModel::title() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("No Track Playing");
    return QString::fromStdString(m_mediaService->getCurrentTrack().title);
}

QString MediaViewModel::artist() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("Connect Media Device");
    return QString::fromStdString(m_mediaService->getCurrentTrack().artist);
}

QString MediaViewModel::album() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("No Media");
    return QString::fromStdString(m_mediaService->getCurrentTrack().album);
}

QString MediaViewModel::genre() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QString();
    return QString::fromStdString(m_mediaService->getCurrentTrack().genre);
}

QString MediaViewModel::durationFormatted() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("0:00");
    return formatTime(m_mediaService->getCurrentTrack().durationSec);
}

QString MediaViewModel::elapsedFormatted() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("0:00");
    return formatTime(m_mediaService->getCurrentTrack().elapsedSec);
}

QString MediaViewModel::remainingFormatted() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("-0:00");
    const auto& track = m_mediaService->getCurrentTrack();
    uint32_t rem = (track.durationSec > track.elapsedSec) ? (track.durationSec - track.elapsedSec) : 0;
    return QStringLiteral("-%1").arg(formatTime(rem));
}

int MediaViewModel::durationSec() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return 0;
    return static_cast<int>(m_mediaService->getCurrentTrack().durationSec);
}

int MediaViewModel::elapsedSec() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return 0;
    return static_cast<int>(m_mediaService->getCurrentTrack().elapsedSec);
}

qreal MediaViewModel::progress() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return 0.0;
    const auto& track = m_mediaService->getCurrentTrack();
    if (track.durationSec == 0) return 0.0;
    return static_cast<qreal>(track.elapsedSec) / static_cast<qreal>(track.durationSec);
}

QString MediaViewModel::coverColor() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("#475569");
    return QString::fromStdString(m_mediaService->getCurrentTrack().coverColor);
}

QString MediaViewModel::coverIcon() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return QStringLiteral("🎵");
    return QString::fromStdString(m_mediaService->getCurrentTrack().coverIcon);
}

bool MediaViewModel::isPlaying() const {
    if (!m_mediaService || !m_mediaService->hasMedia()) return false;
    return m_mediaService->getPlaybackState() == domain::PlaybackState::PLAYING;
}

int MediaViewModel::volume() const {
    if (!m_mediaService) return 65;
    return m_mediaService->getVolume();
}

bool MediaViewModel::isMuted() const {
    if (!m_mediaService) return false;
    return m_mediaService->isMuted();
}

bool MediaViewModel::isShuffle() const {
    if (!m_mediaService) return false;
    return m_mediaService->isShuffle();
}

bool MediaViewModel::isRepeat() const {
    if (!m_mediaService) return false;
    return m_mediaService->isRepeat();
}

QString MediaViewModel::audioSource() const {
    if (!m_mediaService) return QStringLiteral("Bluetooth Audio");
    return QString::fromStdString(m_mediaService->getAudioSource());
}

QVariantList MediaViewModel::queueList() const {
    return m_queueList;
}

int MediaViewModel::currentTrackIndex() const {
    if (!m_mediaService) return 0;
    return static_cast<int>(m_mediaService->getCurrentTrackIndex());
}

bool MediaViewModel::hasMedia() const {
    if (!m_mediaService) return false;
    return m_mediaService->hasMedia();
}

void MediaViewModel::togglePlayPause() {
    if (m_mediaService) {
        m_mediaService->togglePlayPause();
    }
}

void MediaViewModel::nextTrack() {
    if (m_mediaService) {
        m_mediaService->nextTrack();
    }
}

void MediaViewModel::previousTrack() {
    if (m_mediaService) {
        m_mediaService->previousTrack();
    }
}

void MediaViewModel::playTrackAtIndex(int index) {
    if (m_mediaService && index >= 0) {
        m_mediaService->playTrackAtIndex(static_cast<size_t>(index));
    }
}

void MediaViewModel::seek(qreal progressFrac) {
    if (!m_mediaService || !m_mediaService->hasMedia()) return;
    const auto& track = m_mediaService->getCurrentTrack();
    qreal clamped = std::clamp(progressFrac, 0.0, 1.0);
    uint32_t targetSec = static_cast<uint32_t>(clamped * track.durationSec);
    m_mediaService->seekTo(targetSec);
    emit progressChanged();
}

void MediaViewModel::setVolumeLevel(int volume) {
    if (m_mediaService) {
        m_mediaService->setVolume(volume);
    }
}

void MediaViewModel::toggleMute() {
    if (m_mediaService) {
        m_mediaService->toggleMute();
    }
}

void MediaViewModel::toggleShuffle() {
    if (m_mediaService) {
        m_mediaService->toggleShuffle();
        emit modeChanged();
    }
}

void MediaViewModel::toggleRepeat() {
    if (m_mediaService) {
        m_mediaService->toggleRepeat();
        emit modeChanged();
    }
}

void MediaViewModel::setAudioSource(const QString& source) {
    if (m_mediaService) {
        m_mediaService->setAudioSource(source.toStdString());
        emit sourceChanged();
    }
}

void MediaViewModel::toggleEmptyState() {
    if (m_mediaService) {
        bool current = m_mediaService->hasMedia();
        m_mediaService->setEmptyState(current);
        emit hasMediaChanged();
        emit trackChanged();
        emit playbackStateChanged();
        emit progressChanged();
        updateQueueModel();
    }
}

void MediaViewModel::updateQueueModel() {
    m_queueList.clear();
    if (!m_mediaService) return;

    const auto& playlist = m_mediaService->getPlaylist();
    size_t currentIdx = m_mediaService->getCurrentTrackIndex();

    for (size_t i = 0; i < playlist.size(); ++i) {
        const auto& trk = playlist[i];
        QVariantMap item;
        item[QStringLiteral("index")] = static_cast<int>(i);
        item[QStringLiteral("title")] = QString::fromStdString(trk.title);
        item[QStringLiteral("artist")] = QString::fromStdString(trk.artist);
        item[QStringLiteral("album")] = QString::fromStdString(trk.album);
        item[QStringLiteral("genre")] = QString::fromStdString(trk.genre);
        item[QStringLiteral("durationFormatted")] = formatTime(trk.durationSec);
        item[QStringLiteral("isCurrent")] = (i == currentIdx);
        item[QStringLiteral("coverColor")] = QString::fromStdString(trk.coverColor);
        item[QStringLiteral("coverIcon")] = QString::fromStdString(trk.coverIcon);
        m_queueList.append(item);
    }
    emit queueChanged();
}

QString MediaViewModel::formatTime(uint32_t seconds) const {
    const uint32_t mins = seconds / 60;
    const uint32_t secs = seconds % 60;
    return QStringLiteral("%1:%2").arg(mins).arg(secs, 2, 10, QChar('0'));
}

} // namespace driveos::presentation
