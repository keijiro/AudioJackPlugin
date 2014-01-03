// AudioJack plugin entry point.
// By Keijiro Takahashi, 2013, 2014
// https://github.com/keijiro/UnityAudioJack

#import "AudioInputHandler.h"
#import "AudioRingBuffer.h"
#import "SpectrumAnalyzer.h"

static BOOL initialized = NO;

#pragma mark Exported Global Functions

void AudioJackInitialize()
{
    if (!initialized)
    {
        [AudioInputHandler.sharedInstance start];
        initialized = YES;
    }
}

uint32_t AudioJackCountInputChannels()
{
    return (uint32_t)AudioInputHandler.sharedInstance.ringBuffers.count;
}

#pragma mark Exported Analyzer Functions

SpectrumAnalyzer* AudioJackCreateAnalyzer()
{
    return [[SpectrumAnalyzer alloc] init];
}

void AudioJackReleaseAnalyzer(SpectrumAnalyzer *analyzer)
{
    [analyzer release];
}

void AudioJackSetDftPointNumber(SpectrumAnalyzer *analyzer, uint32_t number)
{
    analyzer.pointNumber = number;
}

void AudioJackSetOctaveBandType(SpectrumAnalyzer *analyzer, uint32_t type)
{
    analyzer.octaveBandType = type;
}

void AudioJackAnalyzeAudioInput(SpectrumAnalyzer *analyzer, uint32_t channel, uint32_t mode)
{
    if (mode == 0) {
        [analyzer processAudioInput:AudioInputHandler.sharedInstance channel:channel];
    } else if (mode == 1) {
        [analyzer processAudioInput:AudioInputHandler.sharedInstance channel1:channel channel2:channel + 1];
    } else {
        [analyzer processAudioInput:AudioInputHandler.sharedInstance allChannels:YES];
    }
}

void AudioJackAnalyzerWaveform(SpectrumAnalyzer *analyzer, const float *waveform1, const float *waveform2, float sampleRate)
{
    if (waveform2)
    {
        [analyzer processWaveform:waveform1 withAdding:waveform2 samleRate:sampleRate];
    }
    else
    {
        [analyzer processWaveform:waveform1 samleRate:sampleRate];
    }
}

uint32_t AudioJackGetRawSpectrum(SpectrumAnalyzer *analyzer, float *destination)
{
    SpectrumDataRef source = analyzer.rawSpectrumData;
    memcpy(destination, source->data, sizeof(float) * source->length);
    return (uint32_t)source->length;
}

uint32_t AudioJackGetOctaveBandSpectrum(SpectrumAnalyzer *analyzer, float *destination)
{
    SpectrumDataRef source = analyzer.octaveBandSpectrumData;
    memcpy(destination, source->data, sizeof(float) * source->length);
    return (uint32_t)source->length;
}

#pragma mark Exported RMS Functions

static const float kZeroOffset = 1.5849e-13f;
static const float kRefLevel = 0.70710678118f; // 1/sqrt(2)

float AudioJackCalculateRmsAudioInput(uint32_t channel, float duration)
{
    AudioInputHandler *input = AudioInputHandler.sharedInstance;
    uint32_t sampleCount = duration * input.sampleRate;
    float rms = [[input.ringBuffers objectAtIndex:channel] calculateRMS:sampleCount];
    return 20.0f * log10f(rms / kRefLevel + kZeroOffset);
}

float AudioJackCalculateRmsWaveform(const float *waveform, uint32_t length)
{
    float rms;
    vDSP_rmsqv(waveform, 1, &rms, length);
    return 20.0f * log10f(rms / kRefLevel + kZeroOffset);
}
