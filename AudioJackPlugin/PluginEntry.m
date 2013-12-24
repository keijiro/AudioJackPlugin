// AudioJack plug-in entry point.
// By Keijiro Takahashi, 2013
// https://github.com/keijiro/UnityAudioJack

#import "AudioInputHandler.h"
#import "AudioRingBuffer.h"
#import "SpectrumAnalyzer.h"

static AudioInputHandler *GetAudioInput()
{
    static bool initialized = false;
    AudioInputHandler *input = [AudioInputHandler sharedInstance];
    if (!initialized) {
        [input start];
        initialized = true;
    }
    return input;
}

int AudioJackCountChannels()
{
    return (int)GetAudioInput().ringBuffers.count;
}

float AudioJackGetSampleRate()
{
    return GetAudioInput().sampleRate;
}

float AudioJackGetChannelLevel(int channel)
{
    const float kZeroOffset = 1.5849e-13f;
    const float kRefLevel = 0.70710678118f; // 1/sqrt(2)
    
    AudioInputHandler *input = GetAudioInput();
    int sampleCount = input.sampleRate / 60; // 60 fps
    float rms = [[input.ringBuffers objectAtIndex:channel] calculateRMS:sampleCount];
    
    return 20.0f * log10f(rms / kRefLevel + kZeroOffset);
}

void AudioJackGetRawData(int channel, float *rawData, int samples)
{
    AudioInputHandler *input = GetAudioInput();

    // Retrieve a waveform from the specified channel.
    [[input.ringBuffers objectAtIndex:channel] copyTo:rawData length:samples];
}

void AudioJackGetSpectrum(int channel, int mode, int pointNumber, float *spectrum)
{
    AudioInputHandler *input = GetAudioInput();
    SpectrumAnalyzer *analyzer = [SpectrumAnalyzer sharedInstance];
    
    analyzer.pointNumber = pointNumber;
    
    if (mode == 0) {
        [analyzer processAudioInput:input channel:channel];
    } else if (mode == 1) {
        [analyzer processAudioInput:input channel1:channel channel2:channel + 1];
    } else {
        [analyzer processAudioInput:input];
    }
    
    memcpy(spectrum, analyzer.spectrum, sizeof(float) * pointNumber / 2);
}
