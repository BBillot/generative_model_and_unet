function u = getValidDirection(v, conformity)

%Gets a direction that more or less moves forward from the previous
%direction. Some deviation allowed as a straight tube vessel isn't
%interesting

%Increase if you want a straighter vessel.
%Decerease to make it curve more
v = v/norm(v); %normalize v
NoValidDirection = 1;
while NoValidDirection
    u = makerandunitdirvec(2);
    dp = v'*u;
    if dp>conformity
        NoValidDirection = 0;
    end
end
end

function u1 = makerandunitdirvec(N)
v = randn(N,1);
u1 = bsxfun(@rdivide,v,sqrt(sum(v.^2,2))); %normalize the vector v
end