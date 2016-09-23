%%
%global parameters

[sound, fs, Nbits] = wavread(wavfilename); %����ʹ���������Ƶ�ʺ���������.wav�ļ���Ϊ����
y = sound(:,1);                                       %ȡ������
y = y/max(abs(y)); 
L = length(y);                                          %�ź��ܵ���
frame_time_length = .045;
WL = ceil( frame_time_length*fs);                       %������ 45ms*fs
FL = ceil( .01*fs);                                     %���ص�����/֡��
FN = 1 + floor( (L-WL)/FL);                             %��֡����ÿ֡һ����
%%
%local Params
offset = FL;
N = WL;

H2 = hamming(N);
[f, t, w] = enframe(y, H2, offset);
len = length(f);

%%perform calculation
crossZero = zeros(len,1);
short_energy = zeros(len,1);

for i = 1 : len
    frame = f(i,:)';
    signs = (frame(2:N).*frame(1:N-1))<0;
    diffs = (frame(2:N)-frame(1:N-1) > 0.02);
    crossZero(i) = sum(signs.*diffs);
    short_energy(i) = 10 * log10(frame' * frame / N);
end

%%
%д�ļ�
csvwrite(strcat(resultdir,'crosszero.txt'),crossZero)
csvwrite(strcat(resultdir,'shortenergy.txt'),short_energy)