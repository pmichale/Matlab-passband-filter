clc;clear;close all;
%% 4.1 Zaklady
%load wav file
[y,Fs] = audioread(strcat(strrep(pwd,'src','audio'),'\','192291.wav'));
%pocet vzorku
length_samples = length(y);
%delka v sekundach
length_seconds = length_samples / Fs;
%max a min
max_val = max(y);
min_val = min(y);
%zobrazeni
t = 1:length_samples;
t = t / Fs;
figure(1); plot(t,y);axis tight;
title('192291.wav');xlabel('Time [s]');ylabel('Amplitude [-]');
% print -dpng 1.png;
%% 4.2 Predzpracovani a ramce
%odecteni stredni hodnoty
y_original = y;
y = y - mean(y);
%normalizece
y_normalized = y / max(abs(y));
%rozdeleni na ramce o delce 1024 s prekrytim 512 vzorku
y_ramce = buffer(y_normalized, 1024, 512);
y_ramce(:,1) = [];
figure(2); plot(t(1:size(y_ramce,1)),y_ramce(:,21));axis tight;
title('Rámec 21');xlabel('Time [s]');ylabel('Amplitude [-]');
% print -dpng 2.png;
%% 4.3 DFT
%skip
%% 4.4 Spektrogram
figure
[y_spg,f_spg,t_spg,p_spg] = spectrogram(y,1024,512,1024,Fs);
surf(t_spg,f_spg,10*log10((abs(p_spg)).^2),'EdgeColor','none');colormap(parula(5));
axis tight;view(0,90);xlabel('Time [s]');ylabel('Frequency [Hz]');
% print -dpng spektrogram.png;
%% 4.5 Urceni rusivych frekvenci
% odecteni probehlo z grafu
f1 = round(929.688,-1);
f2 = round(1859.38,-1);
f3 = round(2789.06,-1);
f4 = round(3718.75,-1);
% f1 = 929.688;
% f2 = 1859.38;
% f3 = 2789.06;
% f4 = 3718.75;
if 2*f1 == f2 && 3*f1 == f3 && 4*f1 == f4
    disp('Cosinusovky jsou harmonicky vztazene!')
end
%% 4.6 Generovani signalu
cos1 = cos(2*pi*f1*t); cos2 = cos(2*pi*f2*t);
cos3 = cos(2*pi*f3*t); cos4 = cos(2*pi*f4*t);
y_cos = cos1 + cos2 + cos3 + cos4;
y_cos_normalized = y_cos / max(abs(y_cos)); % normalized to prevent clipping
cospath = strcat(strrep(pwd,'src','audio'),'\','4cos.wav');

audiowrite(cospath, 5e-2*y_cos_normalized, Fs);
figure;
[y_cos_spg,f_cos_spg,t_cos_spg,p_cos_spg] = spectrogram(y_cos,1024,512,1024,Fs); 
surf(t_cos_spg,f_cos_spg,10*log10((abs(p_cos_spg)).^2),'EdgeColor','none'); 
axis tight;view(0,90);xlabel('Time [s]');ylabel('Frequency [Hz]');
% print -dpng 4cos.png;
%% 4.7 Cistici filtr
sp = 35; %sirka pasma
spr = sp+60; %sirka prechodu
f_band = [[f1-spr f1-sp f1+sp f1+spr], [f2-spr f2-sp f2+sp f2+spr],...
    [f3-spr f3-sp f3+sp f3+spr], [f4-spr f4-sp f4+sp f4+spr]];  % freq limits
A = [[1 0 1], [0 1], [0 1], [0 1]]; % 0 = stop; 1 = pass
ripp_dB = 3; % pass - 1
att_dB = -40; % stop - 0
ripp = (power(10,ripp_dB / 20) - 1) / (power(10,ripp_dB/20) + 1); %20log(1+r)-20log(1-r)
att = (power(10,-att_dB / 20)); %-20*log10(a)
dev = [[ripp att ripp], [att ripp], [att ripp], [att ripp]];
[n,Wn,beta,ftype] = kaiserord(f_band,A,dev,Fs);
fir_filter = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
figure
impz(fir_filter, 1, [], Fs)
% print -dpng impz.png;
%% 4.8 Nulove body a poly
figure;zplane(fir_filter);
% print -dpng zeros_poles.png;
%% 4.9 Frekvencni charakteristika
figure;freqz(fir_filter, 1, 2^15, Fs);
% print -dpng freqz.png;
%% 4.10 Filtrace
signal_filtered = filtfilt(fir_filter, 1, y);
signal_filtered_n = signal_filtered / max(abs(signal_filtered));
filteredpath = strcat(strrep(pwd,'src','audio'),'\','clean_bandstop.wav');
audiowrite(filteredpath, signal_filtered_n, Fs);
