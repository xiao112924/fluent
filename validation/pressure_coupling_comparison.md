# Pressure-coupling A/B diagnostic

## Conditions

Both cases use the same 2.8 geometry, original 1–8 harmonic inlet/outlet pressures, `endpoint_constrained` pressure field, Kt/Kr/Ct/Cr, 5% structural damping, prestress, and node-49 -X response definition. Only the pressure-to-structure axial resultant changes.

## Analytical force ratio

For the current uniform pipe, `Di=13 mm`, `Do=16 mm`, `nu=0.30`, `external_pressure=0`, `capped_end=true`, and `thick_wall`:

`Aw*sigma_axial = p*Ai`, therefore `N_wall/(p*Ai) = 1 - 2*nu = 0.400000`.

Thus the new wall-stress load vector is exactly 0.4 times the legacy simple-thrust load vector for every element and every harmonic. Because the structural model is linear in this calculation, every nodal harmonic response is also exactly multiplied by 0.4. Whole-pipe mean/max values scale by 0.4 and dominant-order locations/counts remain unchanged.

## Node 49 result

Legacy simple-thrust response (g): `[0.847366, 0.670092, 0.331963, 0.190447, 0.138021, 0.295398, 0.252328, 0.083900]`

Wall-stress-coupling response (g): `[0.338946, 0.268037, 0.132785, 0.076179, 0.055208, 0.118159, 0.100931, 0.033560]`

Experiment RMSE changes from 0.124683 g to 0.310871 g. MAPE changes from 26.368% to 61.849%. No parameter was tuned.

## Interpretation

The new model is more explicit about pipe-wall axial stress, Poisson coupling, wall formulation and capped-end behavior, which improves physical parameterization and transferability. For this specific uniform thick-wall capped-end case, however, it reduces all pressure-driven structural loads uniformly by 60%, so it does not reshape the 1–8 harmonic spectrum and worsens agreement with the current experiment. This diagnostic does not justify harmonic-specific correction or boundary re-identification.

## Runtime note

The environment does not provide native MATLAB. The legacy node-49 baseline and load norms are the previously verified Python mirror of the same MATLAB equations; the 0.4 A/B transformation follows analytically from the implemented formula, so the relative A/B result is exact for this configuration.
