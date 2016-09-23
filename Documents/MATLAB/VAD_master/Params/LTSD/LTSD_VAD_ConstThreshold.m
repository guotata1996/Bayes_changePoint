%   Long-Term Spectral Deviation VAD 
%   ʹ��ע�⣺ǰ��Inital_FN = 20֡(Լ250ms)���������������ƣ���
%   Reversion: 1.4  Date:2011/8/11
%   Author: ������̨ / QI Ruizhongtai / Charles Q

%clear all;clc;close all;
function [SND, frame_time_length, frame_time] = LTSD_VAD_ConstThreshold(wavfilename,resultdir)
%------------------------------------------------------------------------------------------------------���ļ�
[sound, fs, Nbits] = wavread(wavfilename); %����ʹ���������Ƶ�ʺ���������.wav�ļ���Ϊ����
y = sound(:,1);                                       %ȡ������
%ywgn = wgn(length(y),1,-21);                 %���ɰ�����
%y = y+0*ywgn;                                     %�Ӱ�����
y = y/max(abs(y));                                  %����������һ��
%------------------------------------------------------------------------------------------------------������������
L = length(y);                                          %�ź��ܵ���
frame_time_length = .045;
WL = ceil( frame_time_length*fs);                       %������ 45ms*fs
FL = ceil( .01*fs);                                     %���ص�����/֡��
FN = 1 + floor( (L-WL)/FL);                             %��֡����ÿ֡һ����
N = 9;                                                     %LTSE����
NK = 6;                                                   %�������²���
alpha = 0.95;                                           %�������²���
N1 = 16; N0 = 16;                                  %decision smoothing ����
TH_PARAM = 5;                                       %LTSD��ֵ������babble noise��leopard�ʺ� TH_PARAM=5
Initial_FN = 20;                                        %��ʼ��20֡Ĭ��Ϊ���������г�ʼ��
SND_BEG_N = Initial_FN + 2*N;              %��Ϊ�˷��㶨��ģ�����������ʼ��֡��
%------------------------------------------------------------------------------------------------------��������
y_time = [1 : L]/fs;                                           %y_time��ԭ�ź��±��Ӧ��ʱ��
frame_time = (([1 : FN]' - 1) * FL + 1)/fs;         %frame_time�Ǹ�֡��Ŷ�Ӧ��ʱ�䣨֡��ʼ��ʱ��㣩
hw = hamming(WL);                                        %������
wx = zeros(WL, 1);                                           %wx������ÿ֡�������ź�
K = 2^(ceil(log2(WL)));                                     %FFT�ĵ���
cur_wx_fft = zeros(K,1);                                    %���ɱ���
wx_fft = zeros(K/2, FN);                                    %ÿ֡��FFTϵ��1~K/2
fn = 1; k =1;                                                     %fn��֡���, k ����ʱ�õļ������
energy = zeros(FN,1);                                       %��һ����ʱ����(dB)
LTSE = zeros(K/2, 1);                                         %Long-Term Spectral Envelope
NOISE = LTSE;                                                  %������Ӧ��LTSEֵ
LTSD = zeros(FN, 1);                                         %Long-Term Spectral Deviation
noise_fft = zeros(K/2, FN);                                %������Ƶ�ף��ڷ���������������
SND = zeros(FN,1);                                           %����Speech/Non-speech Decision
UV = SND;                                                       %����ز��θ����������о�
threshold = zeros(FN,1);                                    %��̬LTSD��ֵ
noise_energy = zeros(FN,1);                               %��������(δ��)
%------------------------------------------------------------------------------------------------------��֡����
for fn = 1:FN
    tmpindex = (fn-1)*FL;
    wx =  y(1+ tmpindex : WL + tmpindex);
    %----------------��ʼ--��֡�Ӵ��ź�wx(1:WL)��ͳ�Ʋ�������--------
    %--------------------------------------------------------------------
    %nomarlized short-time energy
    energy(fn) = 10*log10( wx' * wx / WL );
    %Compute FFT of the noisy signal with a hamming window
    cur_wx_fft = abs(fft(wx.*hw, K));
    wx_fft(:,fn) = cur_wx_fft(1:K/2);
    %Initialization
    if fn == Initial_FN
        noise_fft(:,fn) = mean( wx_fft(:,1:fn), 2 ); %ʱ��ƽ��
        noise_fft_std = std( wx_fft(:,1:fn), 0, 2 ); %������Ƶ�εı�׼��
        NOISE = noise_fft(:, fn);
        noise_energy(fn)= mean(energy(1:Initial_FN)); %energy in dB��always<0��  <-40dB very clean speech, >-20dB very noisy speech
        %TH_PARAM = 3;
        threshold(fn) = 10*log10( mean( ((NOISE+TH_PARAM*noise_fft_std).^2) ./ (NOISE.*NOISE) ) );
        THRESHOLD = threshold(fn);
    end
    %Initialization Completed
    %CURRENT decision frame index = fn-N !!
    if fn>SND_BEG_N %SDN_BEG_N = Initial_FN + 2*N;
        snd_fn = fn-N;
    end
    %Compute LTSE(k,fn)
    if fn>SND_BEG_N && fn>2*N && fn<=FN-N
        LTSE = max( wx_fft(:, snd_fn-N:snd_fn+N), [], 2 ); 
    end
    %Compute LTSD(fn)
    if fn>SND_BEG_N
        LTSD(fn) = 10*log10( mean( (LTSE.*LTSE) ./ (NOISE.*NOISE) ) );
    end
    %Decision rule
    if fn>SND_BEG_N && fn>2*N && LTSD(snd_fn) > THRESHOLD
        SND(snd_fn) = 1;
    end
    %Noise updating
    if fn>Initial_FN
        noise_fft(:,fn) = noise_fft(:,fn-1);
        threshold(fn) = threshold(fn-1);
        noise_energy(fn) = noise_energy(fn-1);
    end
    if fn>SND_BEG_N
        if  any( SND(snd_fn-NK:snd_fn) ) == 0 %ȷ�ϵ�ǰ��֮ǰ֡��non-speech 
            noise_fft_snd_fn = mean( noise_fft(:,snd_fn-NK:snd_fn), 2 );
            noise_fft(:,snd_fn) = alpha*noise_fft(:,snd_fn-1) + (1-alpha)*noise_fft_snd_fn;
            NOISE = noise_fft(:,snd_fn);
        end
    end

    
    %�����->U/V�о� ��ԭ��������������غ������β�ͬ�ڷ�babble����������غ������Ρ������������У�
    ds_wx = resample(wx, 2000, fs);%down-sampling to 2000Hz
    WL2 = length(ds_wx); RR = ds_wx' * ds_wx;
    for m = 1 : 40
        R(m) = ds_wx(1:WL2-m)' * ds_wx(m+1:WL2) / RR;
    end
    if ( max(R(7:40)) > 0.5 && min(R(1:10)) < 0 ) %����д��������������У�|| ( fn>1 && UV(fn-1) && energy(fn)>0.12 ) %Decision Rule����
        UV(fn) = 1;
    end
    
    %��ֹƵ��ͻȻ�仯�ķ���������������
    if fn>SND_BEG_N+3
        if SND(snd_fn-1)==0 && SND(snd_fn) == 1
            if sum(SND(snd_fn-N0:snd_fn-2))==0 && sum( UV(snd_fn-1:snd_fn+N) ) <2 %����β����©��
                SND(snd_fn) = 0;
            end
            if energy(snd_fn) < mean(noise_energy(snd_fn-2:snd_fn)) + 3 %3dB��������
                SND(snd_fn) = 0;
            end
        end
    end
    %decision smoothing
    %N1 = 16; N0 = 16;
    if fn>SND_BEG_N+20
        if SND(snd_fn-N1)==0 && SND(snd_fn) == 0 && any(SND(snd_fn-N1+1:snd_fn-1))
            SND(snd_fn-N1+1:snd_fn-1) = zeros(N1-1,1);
        end
        if SND(snd_fn-N0)==1 && SND(snd_fn) == 1 && sum(SND(snd_fn-N0+1:snd_fn-1)) < N0-1
            SND(snd_fn-N0+1:snd_fn-1) = ones(N0-1,1);
        end
    end
    %------------------------------------------------------------------------
    %--------------------����--��֡�Ӵ��źŲ�������------------------------
end
%д�ļ�
csvwrite(strcat(resultdir,'LTSD.txt'), LTSD);

return
