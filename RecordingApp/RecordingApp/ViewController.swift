//
//  ViewController.swift
//  RecordingApp
//
//  Created by Manoj Aher on 17/03/22.
//

import UIKit
import AVFoundation

@frozen
enum PlayerState {
    case playing
    case recording
    case none
}

// MARK: - ViewController
final class ViewController: UIViewController {
    private var recordButton: UIButton!
    private var playButton: UIButton!
    private var audioRecorder: AVAudioRecorder!
    private var player: AVAudioPlayer!
    lazy var recordingSession = AVAudioSession.sharedInstance()

    private var playerState: PlayerState = .none {
        didSet {
            switch playerState {
            case .playing:
                finishRecording(success: false)
            case .recording:
                finishPlaying()
            case .none:
                break
            }
        }
    }

    // MARK: Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        requestMicrophonePermission()
    }

    // MARK: private methods
    private func requestMicrophonePermission() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                        self.loadPlayUI()
                    } else {
                        print("failed to start recording")
                    }
                }
            }
        } catch {
            print("failed to start recording")
        }
    }

    private func loadRecordingUI() {
        recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 300, height: 64))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.setTitleColor(.red, for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }

    private func loadPlayUI() {
        playButton = UIButton(frame: CGRect(x: 64, y: 164, width: 300, height: 64))
        playButton.setTitle("Tap to Play", for: .normal)
        playButton.setTitleColor(.red, for: .normal)
        playButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        playButton.isEnabled = getAudioFilePath() != nil
        view.addSubview(playButton)
    }

    @objc
    private func playButtonTapped() {
        if player == nil {
            startPlaying()
        } else {
            finishPlaying()
        }
    }

    private func startPlaying() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        do {
            try recordingSession.setCategory(.playback, mode: .default)
            try recordingSession.setActive(true)

            playButton.setTitle("Tap to Stop", for: .normal)
            playerState = .playing

            player = try AVAudioPlayer(contentsOf: audioFilename, fileTypeHint: AVFileType.m4a.rawValue)

            guard let player = player else { return }
            player.delegate = self
            player.play()
//            let utterance = AVSpeechUtterance(string: "Wow! I can speak!")
//            utterance.pitchMultiplier = 1.3
//            utterance.rate = AVSpeechUtteranceMinimumSpeechRate * 1.5
//            let synth = AVSpeechSynthesizer()
//            synth.speak(utterance)


        } catch let error {
            print(error.localizedDescription)
        }
    }

    @objc
    private func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }

    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        print(audioFilename)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            playerState = .recording
            audioRecorder.delegate = self
            audioRecorder.record()

            recordButton.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }

    private func finishRecording(success: Bool) {
        guard let _ = audioRecorder else { return }
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
        }
    }

    private func finishPlaying() {
        guard let _ = player else { return }
        player.stop()
        player = nil
        playButton.setTitle("Tap to Play", for: .normal)
    }
}

// MARK: - AVAudioRecorderDelegate
extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finishPlaying()
    }
}

// MARK: - Helper methods
private extension ViewController {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func getAudioFilePath() -> URL? {
        let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        return FileManager.default.fileExists(atPath: audioFilePath.path) ? audioFilePath : nil
    }
}
