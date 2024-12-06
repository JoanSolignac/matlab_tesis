% Inicializar la cámara
camera = webcam(); % Conecta y activa la cámara web para capturar imágenes en tiempo real.

% Cargar el detector de ojos
eyeDetector = vision.CascadeObjectDetector('EyePairBig'); % Detector predefinido para identificar pares de ojos.

% Variables auxiliares para análisis y seguimiento
timer = 0; % Contador para medir la duración de posibles estados de somnolencia.
d = 0; % Contador auxiliar para el cálculo de PERCLOS.
contador = 0; % Contador de parpadeos detectados.

while true
    
    if mod(d, 30) == 0
        clc;
    end

    % Capturar un fotograma RGB
    rgbVideo = snapshot(camera); % Toma una imagen de la cámara.
    subplot(3, 3, 1);
    subimage(rgbVideo); % Muestra el video en color.
    title("Video RGB"); % Título del primer panel.

    % Convertir el video a escala de grises
    video = rgb2gray(rgbVideo); % Convierte la imagen a escala de grises para simplificar el procesamiento.
    flippedImage = flip(video, 2); % Voltea la imagen horizontalmente (efecto espejo).
    subplot(3, 3, 2);
    subimage(flippedImage); % Muestra la imagen volteada.
    title("Video en Escala de Grises, it : ", d); % Título del segundo panel.

    % Detección de ojos en la imagen volteada
    faceBox = step(eyeDetector, flippedImage); faceBox % Detecta pares de ojos usando el detector preentrenado.
    subplot(3, 3, 3);
    subimage(flippedImage); % Muestra la imagen con detección de ojos.
    hold on; % Permite superponer gráficos (como rectángulos).
    title("Región de los Ojos");

    if ~isempty(faceBox) % Si se detectan ojos:
        % Encuentra la región más grande para centrarse en los ojos principales
        biggest_faceBox = 1; %por defecto 1
        for i = 2:size(faceBox, 1)
            if faceBox(i, 3) > faceBox(biggest_faceBox, 3)
                biggest_faceBox = i;
            end
        end

        % Dibujar todos los rectángulos detectados
        for i = 1:size(faceBox, 1)
            rectangle('Position', faceBox(i, :), 'LineWidth', 2, 'EdgeColor', 'y'); % Dibuja rectángulos alrededor de los ojos detectados.
        end

        % Extraer la región más grande correspondiente a los ojos
        faceImage = imcrop(flippedImage, faceBox(biggest_faceBox, :)); % Recorta la región de interés.
        subplot(3, 3, 4);
        subimage(faceImage); % Muestra la subregión correspondiente a los ojos.
        title("Ojos");
    else
        % Si no se detectan ojos
        subplot(3, 3, 4);
        cla; % Limpia el panel anterior.
        title("No se detectaron ojos");
    end
    hold off; % Finaliza el superpuesto de gráficos.

    % Detección del iris dentro de los ojos detectados
    eyesBox = step(eyeDetector, faceImage); % Detecta más características específicas dentro de los ojos.
    if ~isempty(eyesBox)
        % Encuentra la región más grande dentro de los ojos
        biggest_eyesBox = 1;
        for i = 1:size(eyesBox, 1)
            if eyesBox(i, 3) > eyesBox(biggest_eyesBox, 3)
                biggest_eyesBox = i;
            end
        end

        % Ajustar el tamaño de la región para centrarse en el iris
        eyesBox = [eyesBox(biggest_eyesBox, 1), eyesBox(biggest_eyesBox, 2), ...
            eyesBox(biggest_eyesBox, 3) / 3, eyesBox(biggest_eyesBox, 4)];
        eyesImage = imcrop(faceImage, eyesBox(1, :)); % Recorta la subregión del iris.
        eyesImage = imadjust(eyesImage); % Mejora el contraste de la imagen.

        % Buscar círculos (iris) en la subregión
        r = eyesBox(4) / 4; % Tamaño aproximado del radio del iris.
        [centers, radii, metric] = imfindcircles(eyesImage, ...
            [floor(r - r / 4), floor(r + r / 2)], ...
            'ObjectPolarity', 'dark', 'Sensitivity', 0.93); % Encuentra círculos oscuros (iris).

        % Mostrar la detección del iris
        subplot(3, 3, 5);
        subimage(eyesImage);
        hold on;
        viscircles(centers, radii, 'EdgeColor', 'r'); % Dibuja los círculos encontrados.
        title("Detección de Iris");
        hold off;

        % Análisis del parpadeo basado en la detección del iris
        eyesCenter = centers; % Centros de los círculos detectados./
        cent = numel(eyesCenter); % Número de círculos detectados.

       subplot(3, 3, 6);
        cla; % Limpia el panel para nuevos mensajes. 

        if cent == 0
            % Si no se detecta el iris, hay parpadeo
            disp('Hay parpadeo');
            text(0.5, 0.5, 'Hay parpadeo', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'green', 'FontSize', 15);
            timer = timer + 1; % Incrementa el contador de tiempo para somnolencia.
            contador = contador + 1; % Incrementa el contador de parpadeos.
        else
            % Si se detecta el iris, no hay parpadeo
            disp('No hay parpadeo');
            text(0.5, 0.5, 'No hay parpadeo', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'blue', 'FontSize', 15);
        end

        subplot(3, 3, 7), subimage(eyesImage);
        title("Parpadeos : ", contador);

        % Verificar si se alcanza un umbral de somnolencia
        if contador >= 21
            disp('Tienes somnolencia');
            subplot(3, 3, 9);
            text(0.5, 0.5, 'Tienes somnolencia', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'red', 'FontSize', 15);
        end

        % Cálculo del PERCLOS
        d = d + 1; % Incrementar contador auxiliar.
        if d == 125 %aprox 1 minutos
            perclos = (timer / 125) * 100; % Calcula el porcentaje de parpadeo basado en la proporción.
            subplot(3, 3, 8), subimage(eyesImage); % Muestra la imagen actual.
            title([' PERCLOS: ', num2str(perclos)]); % Muestra el porcentaje calculado.
            % Pausa de 5 segundos
            pause(3);

            % Limpiar gráficos residuales y reiniciar variables
            clf; % Limpia todos los subplots y resetea la figura actual.
            d = 0; % Reinicia el contador auxiliar.
            timer = 0; % Reinicia el temporizador.
            contador = 0; % Reinicia el contador de parpadeos.

            % Continúa con la siguiente iteración del bucle
            continue;
        end
    end

    % Añade una pausa para mejorar el rendimiento del sistema
    pause(0.1); % Espera 0.1 segundos antes de la siguiente iteración
end
