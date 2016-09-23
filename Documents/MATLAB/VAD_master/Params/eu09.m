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
%Local Params
M = 23; %num of bins
K = 40; % PPPPPPPPPPCFFFFFFFFF(previous-current-future frames considered togethor)
D = 150; %limit of renewing noise background
beta = 0.84; %��ֵ,����������


%%
%data preparation
f1 = melcepst(y,fs,'M',M, 3 * log(fs),framelen,offset)';

s1 = zeros(length(f1), 1);

rec = [0];
%Initialize
seg0 = f1(:,1: 1 + K - 1);
[U S V] = svd(seg0);
U1 = U(:,1);
V1 = V(:,1);

%%
%segmentation
s1(1) = S(1,1);
ita = beta * s1(1);
Nc = 0;

for start = 1:length(f1)-K+1
   seg = f1(:,start: start+K-1);
   S = U1'*seg*V1;
   if S <= ita
       %is voice
       rec = [rec,start];
       s1(start + start_delay) = S(1,1);
       Nc = 0;
   else
       %is noise
       Nc = Nc + 1;
       s1(start + start_delay) = S(1,1);
       if Nc == D
           U1 = U(:,1);
           V1 = V(:,1);
           ita = beta * S(1,1);
           Nc = 0;
       end
   end
end

%д�ļ�
s1(1:start_delay) = 0;
s1(length(f1) - end_ahead:length(f1)) = 0;
csvwrite(strcat(resultdir,'eu09.txt'),s1);