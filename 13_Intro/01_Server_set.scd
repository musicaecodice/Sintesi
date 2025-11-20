ServerOptions.devices; // Array di devices collegati

s = Server.local;

s.options.inDevice_("Microfono MacBook Air"); // Device in ingresso
s.options.outDevice_("Auricolari esterni");   // Device in uscita
s.options.inDevice_("Altoparlanti MacBook Air");
s.options.numInputBusChannels_(1);            // numero canali in ingresso
s.options.numOutputBusChannels_(8);           // Numero canali in uscita
s.options.numOutputBusChannels = 8;


s.boot;
s.meter;
s.scope;
s.plotTree;

s.reboot;

s.options.numAudioBusChannels;   // Quanti Bus audio ci sono?
s.options.numControlBusChannels; // Quanti Bus di controllo ci sono?