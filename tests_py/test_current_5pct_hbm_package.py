from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT/rel).read_text(encoding='utf-8')

def test_current_boundary_and_five_percent_damping_are_packaged():
    s=read('example_case.m').replace(' ','')
    assert 'cfg.damping.zeta=0.05;' in s
    assert 'Kt=1.598676e7;' in s
    assert 'Kr=1.237086e3;' in s
    assert 'Ct=7.585450e2;' in s
    assert 'Cr=1.900684;' in s

def test_original_unamplified_pressure_expression_is_packaged():
    s=read('example_case.m').replace(' ','')
    assert '+80965.065988*cos(1*w*(t-2))' in s
    assert '+51310.397883*cos(2*w*(t-2))' in s
    assert '+10644.665397*cos(6*w*(t-2))' in s
    assert '-12744.888046*cos(7*w*(t-2))' in s
    assert '-20298.642981*cos(1*w*(t-2))' in s
    assert '+33679.129126*cos(2*w*(t-2))' in s

def test_hbm_entrypoints_and_aft_solver_are_included():
    for rel in [
        'run_hbm.m','run_hbm_sweep.m',
        'src/solve_pipepulse_hbm.m','src/solve_hbm_system.m',
        'src/solve_hbm_frequency_sweep.m','src/hbm_aft_nonlinear_force.m',
        'src/hbm_residual.m'
    ]:
        assert (ROOT/rel).is_file(), rel
    s=read('example_case.m')
    assert 'cfg.boundary.nonlinear.k2' in s
    assert 'cfg.boundary.nonlinear.k3' in s
    assert 'cfg.hbm.n_harmonics = 8;' in s

def test_readme_labels_current_boundary_and_hbm():
    s=read('README.md')
    assert '5%' in s
    assert '1.598676' in s
    assert 'run_hbm.m' in s
    assert 'run_hbm_sweep.m' in s
