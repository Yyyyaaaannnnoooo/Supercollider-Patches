// Spectral image

// MAGS are values between 0 => 1



PackFFT

(1, 0.99 .. 0.01).squared.size

s.boot
// Reminder: This isn't the intended typical usage! It's OK to do this though.
(
x = {
    var mags, phases, chain, sig;
    // Create simple undulating magnitudes
    mags = { FSinOsc.kr(ExpRand(0.1, 1)).range(0, 1) }.dup(100);
    // Then give them a "rolloff" to make the sound less unpleasant
    mags = mags  * ((1, 0.99 .. 0.01).squared);
    // Let's turn the bins on and off at different rates, I'm *sure* that'll sound interesting
    mags = mags * { LFPulse.kr(2 ** IRand(-3, 5)).range(0, 1) }.dup(100);
    // Let's ignore phase for now
    phases = 0.dup(100);
    // We need to create an FFT chain to feed our data in to.
    // The easiest way is to do an FFT on some signal which we then ignore!
    chain = FFT(LocalBuf(512), FSinOsc.ar);
    // Now we can do the packing
    chain = PackFFT(chain, 512, [mags, phases].flop.flatten, 0, 99, 1);
    sig = IFFT(chain);
    sig.dup
}.play
)
x.free;