const Map<String, List<String>> educationCatalog = {
  'Ciencias Económico Administrativas': [
    'TSU en Gestión del Capital Humano',
    'TSU en Contaduría',
    'TSU en Mercadotecnia',
    'Licenciatura en Administración',
    'Licenciatura en Contaduría',
    'Licenciatura en Negocios y Mercadotecnia',
    'Licenciatura en Gestión del Capital Humano',
    'Licenciatura en Innovación de Negocios y Mercadotecnia',
  ],
  'Ciencias Naturales e Ingeniería': [
    'TSU en Protección y Conservación Ambiental',
    'TSU en Manejo de Fauna Silvestre',
    'TSU en Manejo Forestal',
    'TSU en Construcción',
    'TSU en Mantenimiento Industrial',
    'Ingeniería en Manejo de Recursos Naturales',
    'Ingeniería en Mantenimiento Industrial',
    'Ingeniería Civil',
    'Ingeniería en Manejo Sustentable de Recursos Naturales',
  ],
  'Tecnologías de la Información': [
    'TSU en Desarrollo de Software Multiplataforma',
    'TSU en Infraestructura de Redes Digitales',
    'TSU en Automatización',
    'Ingeniería en Tecnologías de la Información e Innovación Digital',
    'Ingeniería Mecatrónica',
    'Ingeniería en Desarrollo y Gestión de Software',
    'Ingeniería en Redes Inteligentes y Ciberseguridad',
  ],
  'Ciencias Exactas': [
    'TSU en Diseño y Moda Industrial en Producción',
    'TSU en Procesos Productivos',
    'TSU en Mecánica Industrial',
    'Ingeniería Mecánica',
    'Ingeniería Industrial',
    'Ingeniería en Diseño Textil y Moda',
    'Ingeniería en Metal Mecánica',
  ],
  'Ciencias de la Salud': [
    'Licenciatura en Terapia Física',
    'Licenciatura en Enfermería',
    'Licenciatura en Médico Cirujano y Partero',
  ],
};

const tsuSemesters = [1, 2, 3, 4, 5, 6];
const superiorSemesters = [7, 8, 9, 10,11];

List<int> cuatrimestresForCareer(String? career) {
  if (career == null) return const [];
  return career.startsWith('TSU en ') ? tsuSemesters : superiorSemesters;
}
