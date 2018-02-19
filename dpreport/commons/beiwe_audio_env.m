function beiwe_audio_env(audio)

[wav fs] = audioread(audio);

% Nummber of seconds per bin of array
scale=10;

% Maximum recording length
dur_max=fs*120;

dur=size(wav,1);
if dur_max>dur
        buffer=dur_max - dur;
        wav_pad=padarray(wav, buffer,nan,'post');
else
        wav_pad=wav(1:dur_max);
end

%vol_max=max(wav);
%disp(vol_max);

epochs=size(wav_pad,1)/fs;

% Currently set to grab mean across 5sec chunks
%wav_epochs=squeeze(mean(reshape(abs(wav_pad)',fs*scale,[])));
wav_epochs=squeeze(median(reshape(abs(wav_pad)',fs*scale,[])));

csvwrite([audio,'_array.csv'],wav_epochs);
