function [ out ] = wrap( in,min,max )
%WRAP 此处显示有关此函数的摘要
%   此处显示详细说明
if(in > max)
    out = in - (max - min);
elseif(in<min)
    out = in +(max-min);
else
    out = in;
end
end

