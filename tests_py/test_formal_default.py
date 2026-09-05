from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_formal_default_is_verified_engineering_baseline():
    s=(ROOT/'example_case.m').read_text(encoding='utf-8').replace(' ','').lower()
    assert "cfg.fluid.pressure_field_model='endpoint_constrained';" in s
    assert "cfg.coupling.pressure_load_model='simple_thrust';" in s
    assert "cfg.prestress.model='legacy';" in s
