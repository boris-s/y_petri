#encoding: utf-8

# Thymidine diphosphate and triphosphate are joined together in a pool.

T23P = Place m!: TDP.default_marking + TTP.default_marking

TDP_ϝ = Transition assignment: true, domain: [ T23P, ADP, ATP ], codomain: TDP,
                   action: lambda { |pool, di, tri| pool * di / ( di + tri ) }
TTP_ϝ = Transition assignment: true, domain: [ T23P, ADP, ATP ], codomain: TTP,
                   action: lambda { |pool, di, tri| pool * tri / ( di + tri ) }

