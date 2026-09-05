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


def test_wall_stress_coupling_is_explicit_diagnostic_not_formal_default():
    base = (ROOT / 'example_case.m').read_text(encoding='utf-8')
    assert "cfg.coupling.pressure_load_model = 'simple_thrust';" in base
    assert "cfg.fluid.pressure_field_model = 'endpoint_constrained';" in base

    profile = (ROOT / 'src' / 'apply_physics_profile.m').read_text(encoding='utf-8')
    assert "pressure_load_model = 'wall_stress_coupling'" in profile
    assert "wall_formulation = 'thin_wall'" in profile
    assert "capped_end = true" in profile

    example = (ROOT / 'example_openpulse_consistent.m').read_text(encoding='utf-8')
    assert "physics_profile = 'openpulse_consistent'" in example


def test_hbm_interfaces_preserved_and_no_frequency_fitting_added():
    for rel in ['run_hbm.m','run_hbm_sweep.m','src/solve_pipepulse_hbm.m','src/hbm_aft_nonlinear_force.m']:
        assert (ROOT / rel).exists(), rel
    hbm = (ROOT / 'src' / 'solve_pipepulse_hbm.m').read_text(encoding='utf-8')
    assert 'pressure_load_model' not in hbm
    all_text = '\n'.join(p.read_text(encoding='utf-8', errors='ignore') for p in ROOT.rglob('*.m'))
    assert 'propagation_loss_scale' not in all_text
    assert 'harmonic_scale' not in all_text
