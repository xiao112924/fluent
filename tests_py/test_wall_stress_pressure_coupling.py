from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_pressure_load_dispatch_and_legacy_branch_present():
    text = (ROOT / 'src' / 'pressure_to_structure_load.m').read_text(encoding='utf-8')
    assert 'pressure_load_model' in text
    assert 'simple_thrust' in text
    assert 'wall_stress_coupling' in text
    assert 'f1 = -p1*A*t' in text
    assert 'f2 = +p2*A*t' in text


def test_wall_pressure_axial_resultant_helper_formulas_present():
    path = ROOT / 'src' / 'wall_pressure_axial_resultant.m'
    assert path.exists()
    text = path.read_text(encoding='utf-8')
    assert 'Aw = pi/4*(Do^2-Di^2);' in text
    assert 'sigma_axial = (p*Di^2 - external_pressure*Do^2)/(Do^2-Di^2);' in text
    assert 'N = Aw*(capped_end - 2*nu)*sigma_axial;' in text
    assert 'stress_axial = (p*Di^2 - external_pressure*Do^2)/(Do^2-Di^2);' in text
    assert 'N = Aw*(capped_end*stress_axial - nu*p*(Do/(Do-Di)-1));' in text
