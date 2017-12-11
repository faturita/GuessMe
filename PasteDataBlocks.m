%datum.data
%data


newdata.X = [datum.data.X;data.X];
newdata.y = [datum.data.y;data.y];
newdata.y_stim = [datum.data.y_stim;data.y_stim];
newdata.trial = data.trial;
newdata.trial = newdata.trial + size(data.X,1);
newdata.flash = data.flash;
newdata.flash = newdata.flash + size(data.X,1);
newdata.trial = [datum.data.trial data.trial];
newdata.flash = [datum.data.flash;data.flash];

