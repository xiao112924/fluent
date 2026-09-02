from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


def test_openpulse_translational_mass_branch_exists_and_legacy_remains():
    text = read('src/beam3d_element.m')
    assert 'openpulse_translational' in text
    assert 'mfluid' in text
    assert 'legacy' in text


def test_named_profile_sets_all_consistent_switches():
    text = read('src/apply_physics_profile.m')
    required = [
        "openpulse_consistent",
        "fluid_mass_model = 'openpulse_translational'",
        "pressure_load_model = 'wall_stress_coupling'",
        "wall_formulation = 'thin_wall'",
        "capped_end = true",
        "wave_speed_model = 'openpulse_compliance'",
        "prestress.model = 'openpulse'",
        "pressure_field_model = 'endpoint_constrained'",
    ]
    for token in required:
        assert token in text
    assert '1.62' not in text
    assert 'harmonic_scale' not in text
    assert 'propagation_loss' not in text


def test_openpulse_example_selects_named_profile():
    text = read('example_openpulse_consistent.m')
    assert "physics_profile = 'openpulse_consistent'" in text
    assert "pressure_field_model = 'endpoint_constrained'" in text


def test_wave_speed_branch_matches_openpulse_compliance_form():
    text = read('src/effective_wave_speed.m').replace(' ', '')
    assert 'openpulse_compliance' in text
    assert 'Di*fluid.bulk/(solid.E*t)' in text
