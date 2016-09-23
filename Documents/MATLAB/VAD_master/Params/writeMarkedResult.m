[t_start, t_end, ~] = lbe2data(lbefilename);

[sound, fs, Nbits] = wavread(wavfilename); %����ʹ���������Ƶ�ʺ���������.wav�ļ���Ϊ����
y = sound(:,1);                                       %ȡ������
y = y/max(abs(y)); 
L = length(y);                                          %�ź��ܵ���
t_total = L / fs;
frame_time_length = .045;
WL = ceil( frame_time_length*fs);                       %������ 45ms*fs
FL = ceil( .01*fs);                                     %���ص�����/֡��
FN = 1 + floor( (L-WL)/FL);                             %��֡����ÿ֡һ����
frame_len = WL;
offset = FL;
res = ones(FN, 1);
for i = 1:FN
    step = (i - 1) * offset + frame_len / 2;
    real_time = step / L * t_total;
    for i1 = 1:length(t_start)
        if t_start(i1) <= real_time & real_time < t_end(i1)
            res(i) = 2;
        end
    end
end

%д�ļ�
csvwrite(strcat(resultdir,'markedres.res'),res)