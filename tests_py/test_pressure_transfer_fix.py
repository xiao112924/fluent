from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(rel): return (ROOT/rel).read_text(encoding='utf-8')

def test_config_defaults_to_endpoint_constrained_pressure_field():
    s=read('example_case.m')
    assert "cfg.fluid.pressure_field_model = 'endpoint_constrained'" in s

def test_fluid_solver_keeps_legacy_and_endpoint_constrained_modes():
    s=read('src/solve_fluid_harmonic.m')
    assert "endpoint_constrained" in s
    assert "acoustic_bvp" in s
    assert "arc" in s.lower() or "snode" in s.lower()

def test_dynamic_pressure_thrust_uses_same_closed_end_sign_as_static():
    s=read('src/pressure_to_structure_load.m').replace(' ','')
    assert 'f1=-p1*A*t;' in s
    assert 'f2=+p2*A*t;' in s or 'f2=p2*A*t;' in s
