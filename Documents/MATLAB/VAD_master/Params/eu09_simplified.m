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
framelen = WL;
start_delay = 20;
end_ahead = 19;
%%
%data preparation
f1 = melcepst(y,fs,'M',M, 3 * log(fs),framelen, offset)';
len = length(f1);
rec = zeros(length(f1), 1);
rec(1:start_delay) = 0;
rec(len - end_ahead: length(f1)) = 0;

%%
%segmentation
for start = 1:len-K+1
   seg = f1(:,start: start+K-1);
   seg = abs(seg);
   [U,S,V] = svd(seg);
   rec(start + start_delay) = U(1,1);
end
%д�ļ�
csvwrite(strcat(resultdir,'eu09_simplified.txt'),rec);