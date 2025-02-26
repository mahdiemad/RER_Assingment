Sets
    bus / 1*3 /
    slack(bus) / 1 /
    Gen / g1*g3 /
    t / t1*t24 /;

Scalars
    Sbase / 100 /;

Alias(bus, node);

*Generators data
Table GenData(Gen,*) 
    b     pmin    pmax
g1  50     0       350
g2  150    0       350
g3  100    0       350;

*Connectivity index of each generator to each bus
Set GBconect(bus, Gen) 
/ 1.g1
  2.g2
  3.g3/;

*Demands of each bus in MW
Table BusData(bus,*) 
    Pd
2   480;

*Bus connectivity matrix
Set conex 
/ 1.2
  2.3
  1.3 /;
conex(bus, node)$(conex(node, bus)) = 1;

*Network technical data
Table branch(bus, node,*) 
    x       Limit
1.2 0.01     400
2.3 0.01     240
1.3 0.01     160;
branch(bus, node, 'x')$(branch(bus, node, 'x') = 0) = branch(node, bus, 'x');
branch(bus, node, 'Limit')$(branch(bus, node, 'Limit') = 0) = branch(node, bus, 'Limit');
branch(bus, node, 'bij')$conex(bus, node) = 1 / branch(bus, node, 'x');

*Reading LoadProfile from csv file according to the provided reference
Parameter LoadProfile(t);

$call =csv2gdx load_profile.csv id=LoadProfile index=1 value=2 useHeader=yes
$gdxin load_profile.gdx
$load LoadProfile

Variables
    OF
    Pij(bus, node, t)
    Pg(Gen, t)
    delta(bus, t);

Equations const1, const2, const3;
const1(bus, node, t)$conex(bus, node) .. Pij(bus, node, t) =e=
    branch(bus, node, 'bij') * (delta(bus, t) - delta(node, t));
const2(bus, t) .. sum(Gen$GBconect(bus, Gen), Pg(Gen, t)) - BusData(bus, 'Pd') * LoadProfile(t) / Sbase =e=
    sum(node$conex(node, bus), Pij(bus, node, t));
const3 .. OF =e= sum((Gen, t), Pg(Gen, t) * GenData(Gen, 'b') * Sbase);

Model loadflow / const1, const2, const3 /;

Pg.lo(Gen, t) = GenData(Gen, 'Pmin') / Sbase;
Pg.up(Gen, t) = GenData(Gen, 'Pmax') / Sbase;
delta.up(bus, t) = pi; delta.lo(bus, t) = -pi; delta.fx(slack, t) = 0;
Pij.up(bus, node, t)$(conex(bus, node)) = branch(bus, node, 'Limit') / Sbase;
Pij.lo(bus, node, t)$(conex(bus, node)) = -branch(bus, node, 'Limit') / Sbase;


Solve loadflow min OF using lp;

Parameter report(t, *) Table of results;

loop(t,
    report(t, 'g1') = Pg.l('g1', t) * Sbase;
    report(t, 'g2') = Pg.l('g2', t) * Sbase;
    report(t, 'g3') = Pg.l('g3', t) * Sbase;

    report(t, 'delta_V1') = delta.l('1', t);
    report(t, 'delta_V2') = delta.l('2', t);
    report(t, 'delta_V3') = delta.l('3', t);

    report(t, 'LMP1') = const2.m('1', t) / Sbase;
    report(t, 'LMP2') = const2.m('2', t) / Sbase;
    report(t, 'LMP3') = const2.m('3', t) / Sbase;

    report(t, 'Load1') = BusData('1', 'Pd') * LoadProfile(t);
    report(t, 'Load2') = BusData('2', 'Pd') * LoadProfile(t);
    report(t, 'Load3') = BusData('3', 'Pd') * LoadProfile(t);
);

display report, Pij.l;