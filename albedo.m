function alb=albedo(T,jmx,x,NoAlbFB_Flag,Tglacier);

% recalculate albedo.

alb=ones(jmx,1)*0.3;

%alternative albedo that depends on latitude (zenith angle)
%alb=0.31+0.08*(3*x.^2-1)/2;

if (NoAlbFB_Flag)
 k=find(abs(x)>=0.95);
else
 k=find(T<=Tglacier);
end

alb(k)=0.6;
