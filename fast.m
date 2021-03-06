% Code up of North and Coakley's seasonal EBM model
% Simplified to eliminate the ocean domain
% Designed to run without a seasonal cycle and hence
% to stop once an equilibrium solution is reached.
% The model uses an implicit trapezoidal method
% so the timestep can be long.

%size of domain.
jmx=151;

% Choose parameters.
%heat diffusion coefficient.
if (exist('Dmag')==0); Dmag = 0.44; end

%heat diffusion coefficient.
if (exist('coldstartflag')==1); 
  if (coldstartflag==1), Toffset = -40; end
end
  
%Simulate Hadley Cell with Lindzen and Farrell plan
if (exist('hadleyflag')==0); hadleyflag = 0.; end

%Remove albedo feedback
if (exist('albedoflag')==0); albedoflag = 0.; end

%Dust albedo / coarse albedo
dust_albedo = 1;
%Scale factor outgassing
scaleCO2 = 1.3;

scaleQ = 0.94; %hoffman and schrag 2000
Toffset = -40; %cold start

%heat capacity over land.
Cl = 0.2; % something small to make it equilibriate quickly

%constants
K = 2.1; % thermal conductivity of ice [W(mK)^-1] for 0 degrees C
G = 40*10^-3; % Geothermal heat flux [W(m^-2)]
Tglacier = -10; % average T at which a ice sheet forms (from North model) [Celcius]
Tbase =  0; %temperature at base of ice sheet [Celcius]

%CO2
initial_co2 = 170; %ppmv
outgassing = scaleCO2 * 3.1*10^10; %[kgCO2/year] <--- Williams et al. 1992
timestep = 10^6; %years
dppmv=outgassing_to_ppmv(outgassing)*timestep; %increase in co2 ppmv per timestep
total_time = 2*10^8; %years
t = 0:timestep:total_time;
meanT = t;%create array for the mean temperature over time
equatorH = t;%create array for the equatorial ice thickness over time
iceline = t;%create array for the iceline over time [degrees latitude]
co2_dev = t;%create array for the CO2 concentration development over time [ppmV]
albedoMean = t; %create mean albedo array over time

%set up x array.
delx = 2.0/jmx;
x = [-1.0+delx/2:delx:1.0-delx/2]';
phi = asin(x)*180/pi;

%set up inital T profile 
T = 20*(1-2*x.^2);
T=T(:);
T=T+Toffset;
%load T_final
Tinit=T;

for j=1:length(t) % timestep increments
    % as in Caldeira et al. Box 1
    co2 = (initial_co2 + (j-1)*dppmv)*timestep/(timestep+(j-1)*dppmv); %calculate co2 concentration in ppmv, adjusted for it's own increase as well
    co2_dev(j) = co2;
    phi_co2 = log(co2 / 300);
    
    B =  1.953 - 0.04866 * phi_co2 + 0.01309 * phi_co2 .^ 2 - 0.002577 * phi_co2 .^3;
    A = -326.4 + 9.161 * phi_co2 - 3.164 * phi_co2.^2 + 0.5468 * phi_co2.^3; 
    A = A + B * 273.15; % correction Kelvin to Celsius
    
    %time step in fraction of year
    delt=1./50;
    NMAX=1000; 

    %obtain annual array of daily averaged-insolation.
    %[insol] = sun(x);
    %Legendre polynomial realizatin of mean annual insol.
    Q = 338.5;
    S = Q*(1-0.241*(3*x.^2-1)); 
    S=scaleQ*S; S=S(:);
    

    %setup D(x) if simulating the Hadley Cell
    %and calculate the matrix Mh and invM.
    if (hadleyflag)
      xmp=[-1:delx:1];
      D=Dmag*(1+9*exp(-(xmp/sin(25*pi/180)).^6));
      D=D(:);
      [invM,Mh]=setupfastM(delx,jmx,D,B,Cl,delt);
    else
      D=Dmag*ones(jmx+1,1);
      [invM,Mh]=setupfastM(delx,jmx,D,B,Cl,delt);
    end

    %Boundary conditions
    %Set up initial value for h.
     alb=albedo(T,jmx,x,albedoflag,dust_albedo,Tglacier,j, timestep);
     src   = (1-alb).*S/Cl-A/Cl; src=src(:);
     h=Mh*T+src;

    %Global mean temperature
    Tglob=mean(T);

    time = 0;
    meanTdev = 0;
    % Timestepping loop
    for n=1:NMAX
       Tglob_prev = Tglob;

    % Calculate src for this loop.
       alb=albedo(T,jmx,x,albedoflag,dust_albedo,Tglacier,j, timestep);
       albedoMean(j) = mean(alb);
       src=((1-alb).*S-A)/Cl; src=src(:);

    % Calculate new T.
       T=-invM*(0.5*(h+src)+T/delt);

    % Calculate h for next loop.
       h=Mh*T+src;

    % Check to see if global mean temperature has converged
       Tglob=mean(T);
       time(n)=n;
       meanTdev(n)=Tglob;
       Tchange = Tglob-Tglob_prev;
       if (abs(Tchange) < 1.0e-12), break; end
    end

    %save T_final.mat T

    % compute meridional heat flux and its convergence
    a=6.37e+6; % earth radius in meters
    [invM,Mh]=setupfastM(delx,jmx,D,0.,1.0,delt);
    Dmp=0.5*( D(2:jmx+1)+D(1:jmx) );
    divF=Mh*T;
    F=-2*pi*a^2*sqrt(1-x.^2).*Dmp.*gradient(T,delx);

    %calculate ice thickness assuming no advection
    T2 = T;
    T2(T2>Tglacier) = 0; %no glacier forms where T is higher than Tglacier
    ice_thickness = -K*(T2-Tbase)/G;
    iceline(j) = 90-asin(length(ice_thickness(ice_thickness>0))/jmx)*180/pi; %determine the ice line, and convert to latitude
    equatorH(j) = ice_thickness((jmx+1)/2); %get equator ice thickness
    
    meanT(j)=Tglob;
    
end

collapsetime = (length(meanT(meanT<0))-1)*timestep; %Snowball earth exists until the meanT suddenly jumps above 0
co2_collapsetime = co2_dev(collapsetime/timestep); %obtain the co2 concentration upon collapse
albedo_collapsetime = albedoMean(collapsetime/timestep); %obtain the mean albedo upon collapse

figure;
set(gcf, 'WindowState', 'maximized');
subplot(4,1,1);
plot(t,meanT);
xlabel('time (yr)')
ylabel([char(176) 'C'])
title('Mean T');
subplot(4,1,2);
plot(t,co2_dev);
xlabel('time (yr)')
ylabel('ppmV')
title('CO2-concentration');
subplot(4,1,3);
plot(t,albedoMean);
xlabel('time (yr)')
title('albedo');
subplot(4,1,4);
plot(t,equatorH);
xlabel('time (yr)')
ylabel('H (m)')
title('Equatorial ice thickness');
u=axis; pos=u(3)-0.4*(u(4)-u(3));
text(-90,pos,['At the point of deglaciation: time = ',num2str(collapsetime/10^6,'%7.0f'),...
            ' Gy,    CO2-level = ',num2str(co2_collapsetime,'%7.0f'),...
            ' ppmv,    Average albedo = ',num2str(albedo_collapsetime,'%7.4f')] );

%     figure; 
%     set(gcf, 'WindowState', 'maximized');
%     subplot(4,1,1);
%     plot(phi,T,'.-','linewidth',1.5)
%     ylabel('Temperature'); xlabel('latitude');
%     %set(gca,'position',[0.1300    0.71    0.7750    0.21]);
%     title(['Global mean temperature is ',num2str(Tglob,'%7.2f'), ', CO2 is ',num2str(co2)]);
%     grid on;
% 
%     %subplot(4,1,2);
%     %plot(phi,F*1e-15,'.-','linewidth',1.5)
%     %ylabel('Poleward Heat Flux (10^{15} W)'); xlabel('latitude');
%     %set(gca,'position',[0.1300    0.41    0.7750    0.21]);
%     %grid on;
% 
%     subplot(4,1,2);
%     plot(phi,ice_thickness,'.-','linewidth',1.5)
%     ylabel('Ice thickness (m)'); xlabel('latitude');
%     grid on;
% 
%     subplot(4,1,3);
%     plot(phi,divF,'.-',phi,(1-alb).*S,'o',phi,A+B*T,'.','linewidth',1.5)
%     ylabel('Energy Balance Terms (W m^{-2})'); xlabel('latitude');
%     %set(gca,'position',[0.1300    0.130    0.7750    0.21]);
%     legend('\nabla F','SWd','LWu');
%     grid on;
%     u=axis; pos=u(3)-0.4*(u(4)-u(3));
%     text(-90,pos,['D = ',num2str(Dmag,'%7.2f'),...
%            ',    Q/Qo = ',num2str(scaleQ,'%7.3f'),...
%            ',    A = ',num2str(A,'%7.1f'),...
%            ',    B = ',num2str(B,'%7.1f'),...
%            ',    Toffset = ',num2str(Toffset,'%7.1f')] );
% 
%     subplot(4,1,4);
%     plot(time, meanTdev)
%     ylabel('Mean T'); xlabel('time');
%     %set(gca,'position',[0.1300    0.130    0.7750    0.21]);
%     grid on;
