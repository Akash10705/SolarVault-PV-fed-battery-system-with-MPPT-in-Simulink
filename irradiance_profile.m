% 1 second = 1 hour
t_irr = (0:24)';

% Irradiance in W/m^2
G_irr = [0
         0
         0
         0
         0
         20
         100
         250
         400
         550
         700
         850
         950
         1000
         950
         850
         700
         550
         400
         250
         100
         20
         0
         0
         0];

irradianceprofile = [t_irr G_irr];