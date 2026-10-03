#pragma once

#include "SafetyPolicy.hpp"
#include <algorithm>
#include <functional>
#include <string>
#include <vector>

namespace driveos::domain {

/**
 * @brief Audio playback state.
 */
enum class PlaybackState : uint8_t {
    STOPPED = 0,
    PLAYING,
    PAUSED
};

/**
 * @brief Media track metadata.
 */
struct MediaTrack {
    std::string id{"track_1"};
    std::string title{"Midnight Drive"};
    std::string artist{"DriveOS Synthetics"};
    std::string album{"Neon Cockpit"};
    std::string genre{"Synthwave"};
    uint32_t durationSec{230};
    uint32_t elapsedSec{102};
    std::string coverColor{"#0284C7"};
    std::string coverIcon{"🎧"};
};

/**
 * @brief Application domain service managing audio playback and media state.
 * 
 * Manages media controls (play/pause/skip), volume adjustment, track metadata,
 * playlist queue, and simulated local automotive audio playback.
 */
class MediaService {
public:
    using TrackChangedCallback = std::function<void(const MediaTrack&)>;
    using PlaybackChangedCallback = std::function<void(PlaybackState)>;
    using VolumeChangedCallback = std::function<void(int volumePercent)>;
    using PlaylistChangedCallback = std::function<void(const std::vector<MediaTrack>&)>;

    explicit MediaService(SafetyPolicy* safetyPolicy)
        : m_safetyPolicy(safetyPolicy)
    {
        initializePlaylist();
    }

    virtual ~MediaService() = default;

    virtual void togglePlayPause() {
        if (!m_hasMedia) return;

        m_playbackState = (m_playbackState == PlaybackState::PLAYING)
                              ? PlaybackState::PAUSED
                              : PlaybackState::PLAYING;
        notifyPlaybackChanged();
    }

    virtual void play() {
        if (!m_hasMedia) return;
        m_playbackState = PlaybackState::PLAYING;
        notifyPlaybackChanged();
    }

    virtual void pause() {
        m_playbackState = PlaybackState::PAUSED;
        notifyPlaybackChanged();
    }

    virtual void nextTrack() {
        if (!m_hasMedia || m_playlist.empty()) return;

        if (m_isRepeat) {
            m_currentTrack.elapsedSec = 0;
        } else if (m_isShuffle) {
            m_currentTrackIndex = (m_currentTrackIndex + 2) % m_playlist.size();
            m_currentTrack = m_playlist[m_currentTrackIndex];
            m_currentTrack.elapsedSec = 0;
        } else {
            m_currentTrackIndex = (m_currentTrackIndex + 1) % m_playlist.size();
            m_currentTrack = m_playlist[m_currentTrackIndex];
            m_currentTrack.elapsedSec = 0;
        }

        notifyTrackChanged();
    }

    virtual void previousTrack() {
        if (!m_hasMedia || m_playlist.empty()) return;

        if (m_currentTrack.elapsedSec > 5) {
            // If already played more than 5s, restart current track
            m_currentTrack.elapsedSec = 0;
        } else {
            if (m_currentTrackIndex == 0) {
                m_currentTrackIndex = m_playlist.size() - 1;
            } else {
                m_currentTrackIndex--;
            }
            m_currentTrack = m_playlist[m_currentTrackIndex];
            m_currentTrack.elapsedSec = 0;
        }

        notifyTrackChanged();
    }

    virtual void playTrackAtIndex(size_t index) {
        if (!m_hasMedia || index >= m_playlist.size()) return;

        m_currentTrackIndex = index;
        m_currentTrack = m_playlist[index];
        m_currentTrack.elapsedSec = 0;
        m_playbackState = PlaybackState::PLAYING;

        notifyTrackChanged();
        notifyPlaybackChanged();
    }

    virtual void seekTo(uint32_t elapsedSec) {
        if (!m_hasMedia) return;
        m_currentTrack.elapsedSec = std::min(elapsedSec, m_currentTrack.durationSec);
        notifyTrackChanged();
    }

    virtual bool setVolume(int volumePercent) {
        m_volume = std::clamp(volumePercent, 0, 100);
        notifyVolumeChanged();
        return true;
    }

    virtual void toggleMute() {
        m_isMuted = !m_isMuted;
        notifyVolumeChanged();
    }

    virtual void toggleShuffle() {
        m_isShuffle = !m_isShuffle;
    }

    virtual void toggleRepeat() {
        m_isRepeat = !m_isRepeat;
    }

    virtual void setAudioSource(const std::string& source) {
        m_audioSource = source;
    }

    virtual void setEmptyState(bool empty) {
        m_hasMedia = !empty;
        if (empty) {
            m_playbackState = PlaybackState::STOPPED;
        } else {
            m_playbackState = PlaybackState::PLAYING;
            m_currentTrack = m_playlist[m_currentTrackIndex];
        }
        notifyPlaybackChanged();
        notifyTrackChanged();
    }

    [[nodiscard]] virtual PlaybackState getPlaybackState() const { return m_playbackState; }
    [[nodiscard]] virtual MediaTrack getCurrentTrack() const { return m_currentTrack; }
    [[nodiscard]] virtual int getVolume() const { return m_volume; }
    [[nodiscard]] virtual bool isMuted() const { return m_isMuted; }
    [[nodiscard]] virtual bool isShuffle() const { return m_isShuffle; }
    [[nodiscard]] virtual bool isRepeat() const { return m_isRepeat; }
    [[nodiscard]] virtual bool hasMedia() const { return m_hasMedia; }
    [[nodiscard]] virtual const std::string& getAudioSource() const { return m_audioSource; }
    [[nodiscard]] virtual const std::vector<MediaTrack>& getPlaylist() const { return m_playlist; }
    [[nodiscard]] virtual size_t getCurrentTrackIndex() const { return m_currentTrackIndex; }

    virtual void registerTrackCallback(TrackChangedCallback callback) {
        m_trackCallbacks.push_back(std::move(callback));
    }

    virtual void registerPlaybackCallback(PlaybackChangedCallback callback) {
        m_playbackCallbacks.push_back(std::move(callback));
    }

    virtual void registerVolumeCallback(VolumeChangedCallback callback) {
        m_volumeCallbacks.push_back(std::move(callback));
    }

    virtual void registerPlaylistCallback(PlaylistChangedCallback callback) {
        m_playlistCallbacks.push_back(std::move(callback));
    }

private:
    void notifyTrackChanged() {
        for (const auto& cb : m_trackCallbacks) {
            if (cb) cb(m_currentTrack);
        }
    }

    void notifyPlaybackChanged() {
        for (const auto& cb : m_playbackCallbacks) {
            if (cb) cb(m_playbackState);
        }
    }

    void notifyVolumeChanged() {
        for (const auto& cb : m_volumeCallbacks) {
            if (cb) cb(m_isMuted ? 0 : m_volume);
        }
    }

    void notifyPlaylistChanged() {
        for (const auto& cb : m_playlistCallbacks) {
            if (cb) cb(m_playlist);
        }
    }
    void initializePlaylist() {
        m_playlist = {
            {
                "trk_01",
                "Midnight Drive",
                "DriveOS Synthetics",
                "Neon Cockpit",
                "Synthwave",
                230,
                102,
                "#0284C7",
                "🎧"
            },
            {
                "trk_02",
                "Cyberpunk Horizon",
                "Kavinsky & Daft Sound",
                "Outrun 2077",
                "Electro",
                275,
                0,
                "#4F46E5",
                "🏙️"
            },
            {
                "trk_03",
                "Electric Boulevard",
                "Synthwave Pulse",
                "High Voltage",
                "Ambient Tech",
                210,
                0,
                "#059669",
                "⚡"
            },
            {
                "trk_04",
                "Solar Drift",
                "Aero Soundscapes",
                "Orbital Cruising",
                "Deep House",
                260,
                0,
                "#D97706",
                "🌅"
            },
            {
                "trk_05",
                "Autobahn Velocity",
                "Kraftwerk Resonance",
                "Infinite Highway",
                "Minimalist Electro",
                312,
                0,
                "#0284C7",
                "🏎️"
            },
            {
                "trk_06",
                "Pacific Breeze",
                "Coastal Acoustic",
                "Sunset Boulevard",
                "Chill Acoustic",
                198,
                0,
                "#059669",
                "🌊"
            }
        };

        m_currentTrackIndex = 0;
        m_currentTrack = m_playlist[0];
    }

    SafetyPolicy* m_safetyPolicy{nullptr};
    PlaybackState m_playbackState{PlaybackState::PLAYING};
    std::vector<MediaTrack> m_playlist;
    size_t m_currentTrackIndex{0};
    MediaTrack m_currentTrack{};
    int m_volume{65};
    bool m_isMuted{false};
    bool m_isShuffle{false};
    bool m_isRepeat{false};
    bool m_hasMedia{true};
    std::string m_audioSource{"Bluetooth Audio"};

    std::vector<TrackChangedCallback> m_trackCallbacks;
    std::vector<PlaybackChangedCallback> m_playbackCallbacks;
    std::vector<VolumeChangedCallback> m_volumeCallbacks;
    std::vector<PlaylistChangedCallback> m_playlistCallbacks;
};

} // namespace driveos::domain
