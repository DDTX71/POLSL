clear all
clc

a = 0;
b = 1;
h = 0.1;
yata = 1;

[Xs, Ys, Fxys, Dys] = diffeq(a, b, h, yata)


function fxy = f(x, y)
    fxy = 2 * x * y;
end


function [Xs, Ys, Fxys, Dys] = diffeq(a, b, h, yata)
    Xs = a:h:b;
    Ys   = zeros(1, length(Xs));
    Fxys = zeros(1, length(Xs));
    Dys  = zeros(1, length(Xs));
    
    Ys(1) = yata;
    Fxys(1) = f(Xs(1), Ys(1));
    Dys(1) = h * Fxys(1);
    
    for i = 2:length(Xs)
        Ys(i)   = Ys(i-1)+Dys(i-1);
        Fxys(i) = f(Xs(i), Ys(i));
        Dys(i)  = h * Fxys(i);
    end
end