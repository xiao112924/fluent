from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(rel): return (ROOT/rel).read_text(encoding='utf-8')

def test_fetm_admittance_helper_exists_and_uses_openpulse_formula():
    p=ROOT/'src/fetm_acoustic_admittance.m'
    assert p.exists()
    s=p.read_text(encoding='utf-8').replace(' ','')
    assert 'sin(k*L)' in s
    assert 'cos(k*L)' in s
    assert '1i/(Zv*sin(k*L))' in s
    assert '[-c,1;1,-c]' in s

def test_acoustic_termination_supports_passive_models():
    p=ROOT/'src/acoustic_termination_impedance.m'
    assert p.exists()
    s=p.read_text(encoding='utf-8').lower()
    for token in ['anechoic','normalized_constant','normalized_rlc','specific_volume_impedance']:
        assert token in s
    assert 'r < 0' in s or 'r<0' in s

def test_fluid_solver_dispatches_fetm_impedance_without_dual_hard_pressure():
    s=read('src/solve_fluid_harmonic.m')
    assert 'fetm_impedance' in s
    assert 'solve_fetm_impedance_pressure' in s
    helper=read('src/solve_fetm_impedance_pressure.m').lower()
    assert 'source_end' in helper
    assert 'termination' in helper
    assert 'known = unique([inletnode,outletnode])' not in helper.replace(' ','')

def test_fetm_example_keeps_legacy_default_unchanged():
    base=read('example_case.m')
    assert "cfg.fluid.pressure_field_model = 'endpoint_constrained'" in base
    ex=read('example_fetm_impedance.m')
    assert "pressure_field_model = 'fetm_impedance'" in ex
    assert '1.62' not in ex
    assert 'harmonic_scale' not in ex

def test_hbm_files_are_not_referenced_by_fetm_helpers():
    combined='\n'.join(read(p) for p in [
        'src/fetm_acoustic_admittance.m',
        'src/acoustic_termination_impedance.m',
        'src/solve_fetm_impedance_pressure.m'])
    assert 'run_hbm' not in combined.lower()
    assert 'harmonic_scale' not in combined.lower()
