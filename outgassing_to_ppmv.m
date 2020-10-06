function dppmv=outgassing_to_ppmv(outgassing);
    %constants
    Mco2 = 43.44*10^-3; %[kg/mole]
    Matm = 28.96*10^-3;%molar mass of atmospheric gas [kg/mole]

    %variables
    P = 10^5; %pressure of the atmosphere at sea level [Pascal] <--- what was the pressure 500 mya?

    %calculate the amount of moles in atmosphere
    Natm = (P*5.1945385*10^13)/Matm; %amount of moles of all gases in the atmopshere [mole], 5.19*10^13 is the Earth's surface area divided by g.

    %calculate the change in ppmV of CO2 in the atmosphere
    dppmv = outgassing/(Mco2*Natm) * 10^6; %increase in ppmV of CO2 / year [ppmv/y]
