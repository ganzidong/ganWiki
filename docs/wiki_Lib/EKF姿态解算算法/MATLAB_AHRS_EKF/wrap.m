function [ out ] = wrap( in,min,max )
%WRAP �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
if(in > max)
    out = in - (max - min);
elseif(in<min)
    out = in +(max-min);
else
    out = in;
end
end

