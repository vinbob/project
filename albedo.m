function alb=albedo(T,jmx,x,NoAlbFB_Flag,dust_albedo,Tglacier,j, timestep)

% recalculate albedo.

alb=ones(jmx,1)*0.3;

if (dust_albedo)
    %alternative albedo that depends on latitude (zenith angle)
    alb=0.31+0.08*(3*x.^2-1)/2;

    if (NoAlbFB_Flag)
     k=find(abs(x)>=0.95);
    else
     k=find(T<=Tglacier);
    end

    c_dust = 1.39e7; % per year
    gamma = 20; % dust sensitivity parameter kg/m2
    % albedo_max = 0.9 % as per LMDz, see LeHir et al
    albedo_max = 0.65; %see fig 1 LeHir et al.
    albedo_min = 0.18; %see fig 1 LeHir et al.
    surface_earth = 510.1 * 10^15; %m2

    dust_density_min = 0;
    dust_density_max = 0.036; %kg

    % albedo_ice = (albedo_max-albedo_min)*exp(-gamma*c_dust*(j - 1) * timestep / surface_earth)+albedo_min;
    albedo_ice = c_dust * (j-1) * timestep / surface_earth * (albedo_min - albedo_max) / (dust_density_max - dust_density_min) + albedo_max;
    alb(k) = albedo_ice;
    % alb(k) = 0.6;

    % albedo_ice=(albedo_max-albedo_min)*exp(-gamma*c_dust)+albedo_min, 
    % where c_dust is dust deposition (kg/m2) and gamma is a dust sensitivty parameter,
    % set to 20 m2/kg. Use e.g. c_dust /year=1.39e7kg/year. (can also be done simpler)
else
    if (NoAlbFB_Flag)
     k=find(abs(x)>=0.95);
    else
     k=find(T<=Tglacier);
    end
    alb(k)=0.6;
end

