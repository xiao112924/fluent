from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_static_openpulse_load_uses_same_wall_resultant_helper_as_dynamic():
    path = ROOT / 'src/static_pipe_pressure_load_openpulse.m'
    assert path.exists()
    text = path.read_text(encoding='utf-8')
    assert 'wall_pressure_axial_resultant' in text
    assert 'f1 = -N1*t' in text
    assert 'f2 = +N2*t' in text


def test_prestress_uses_openpulse_te_definition():
    text = (ROOT / 'src/solve_static_prestress_state.m').read_text(encoding='utf-8')
    assert 'Fp = wall_pressure_axial_resultant' in text
    assert 'Neff(e) = Nwall(e) - Fp' in text


def test_geometric_stiffness_keeps_legacy_interface():
    text = (ROOT / 'src/solve_static_prestress_state.m').read_text(encoding='utf-8')
    segment = text.split('beam3d_geometric_stiffness', 1)[1].split(';', 1)[0]
    assert 'get_fluid_mass_model(cfg)' not in segment
