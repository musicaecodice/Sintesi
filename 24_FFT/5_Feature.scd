(
s = Server.local;
s.options.memSize_(2.pow(20)); // per Delay...
s.boot;
s.freqscope;
{s.plotTree}.defer(3);
)

PV_BufRd // Scratcher senza trasposizione...