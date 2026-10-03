#pragma once

#include "BaseViewModel.hpp"
#include "domain/MediaService.hpp"
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>

namespace driveos::presentation {

/**
 * @brief ViewModel for the Media experience in DriveOS.
 * 
 * Provides reactive bindings for current track metadata, playback state,
 * playback timeline scrubber, volume management, playlist queue, and simulated sources.
 */
class MediaViewModel : public BaseViewModel {
    Q_OBJECT

    // Current Track Metadata
    Q_PROPERTY(QString title READ title NOTIFY trackChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY trackChanged)
    Q_PROPERTY(QString album READ album NOTIFY trackChanged)
    Q_PROPERTY(QString genre READ genre NOTIFY trackChanged)
    Q_PROPERTY(QString durationFormatted READ durationFormatted NOTIFY trackChanged)
    Q_PROPERTY(QString elapsedFormatted READ elapsedFormatted NOTIFY progressChanged)
    Q_PROPERTY(QString remainingFormatted READ remainingFormatted NOTIFY progressChanged)
    Q_PROPERTY(int durationSec READ durationSec NOTIFY trackChanged)
    Q_PROPERTY(int elapsedSec READ elapsedSec NOTIFY progressChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString coverColor READ coverColor NOTIFY trackChanged)
    Q_PROPERTY(QString coverIcon READ coverIcon NOTIFY trackChanged)

    // Playback State
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStateChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)
    Q_PROPERTY(bool isMuted READ isMuted NOTIFY volumeChanged)
    Q_PROPERTY(bool isShuffle READ isShuffle NOTIFY modeChanged)
    Q_PROPERTY(bool isRepeat READ isRepeat NOTIFY modeChanged)
    Q_PROPERTY(QString audioSource READ audioSource NOTIFY sourceChanged)

    // Queue / Library & States
    Q_PROPERTY(QVariantList queueList READ queueList NOTIFY queueChanged)
    Q_PROPERTY(int currentTrackIndex READ currentTrackIndex NOTIFY trackChanged)
    Q_PROPERTY(bool hasMedia READ hasMedia NOTIFY hasMediaChanged)

public:
    explicit MediaViewModel(domain::MediaService* mediaService, QObject* parent = nullptr);
    ~MediaViewModel() override = default;

    // Getters
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString artist() const;
    [[nodiscard]] QString album() const;
    [[nodiscard]] QString genre() const;
    [[nodiscard]] QString durationFormatted() const;
    [[nodiscard]] QString elapsedFormatted() const;
    [[nodiscard]] QString remainingFormatted() const;
    [[nodiscard]] int durationSec() const;
    [[nodiscard]] int elapsedSec() const;
    [[nodiscard]] qreal progress() const;
    [[nodiscard]] QString coverColor() const;
    [[nodiscard]] QString coverIcon() const;

    [[nodiscard]] bool isPlaying() const;
    [[nodiscard]] int volume() const;
    [[nodiscard]] bool isMuted() const;
    [[nodiscard]] bool isShuffle() const;
    [[nodiscard]] bool isRepeat() const;
    [[nodiscard]] QString audioSource() const;

    [[nodiscard]] QVariantList queueList() const;
    [[nodiscard]] int currentTrackIndex() const;
    [[nodiscard]] bool hasMedia() const;

    // Invocable Actions
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void previousTrack();
    Q_INVOKABLE void playTrackAtIndex(int index);
    Q_INVOKABLE void seek(qreal progressFrac);
    Q_INVOKABLE void setVolumeLevel(int volume);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void toggleShuffle();
    Q_INVOKABLE void toggleRepeat();
    Q_INVOKABLE void setAudioSource(const QString& source);
    Q_INVOKABLE void toggleEmptyState();

signals:
    void trackChanged();
    void playbackStateChanged();
    void progressChanged();
    void volumeChanged();
    void modeChanged();
    void sourceChanged();
    void queueChanged();
    void hasMediaChanged();

private:
    void updateQueueModel();
    QString formatTime(uint32_t seconds) const;

    domain::MediaService* m_mediaService{nullptr};
    QTimer* m_progressTimer{nullptr};
    QVariantList m_queueList;
};

} // namespace driveos::presentation
