function [ C ] = diagDiv( A,B )
%DIAGDIV �Խ�����C(i,i) = A(i,i) / B(i,i)������Ϊ0
%   ֻ�ʺ�ͬά�ȶԽ���
C = zeros(length(A));
for i = 1 : length(A)
     C(i,i) = A(i,i) / B(i,i);
end
end

