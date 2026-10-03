package br.com.library.service;

import br.com.library.dto.request.AutorRequest;
import br.com.library.dto.response.AutorResponse;
import br.com.library.dto.response.LivroResponse;
import br.com.library.exception.RecursoNaoEncontradoException;
import br.com.library.entity.Autor;
import br.com.library.repository.AutorRepository;
import br.com.library.repository.LivroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class AutorService {

    private final AutorRepository autorRepository;
    private final LivroRepository livroRepository;

    @Transactional(readOnly = true)
    public List<AutorResponse> listar() {
        return autorRepository.findAll().stream().map(AutorResponse::de).toList();
    }

    @Transactional(readOnly = true)
    public AutorResponse buscar(Long id) {
        return AutorResponse.de(buscarEntidade(id));
    }

    @Transactional(readOnly = true)
    public List<LivroResponse> listarLivros(Long autorId) {
        buscarEntidade(autorId);
        return livroRepository.findByAutorId(autorId).stream().map(LivroResponse::de).toList();
    }

    @Transactional
    public AutorResponse criar(AutorRequest dados) {
        Autor autor = new Autor(dados.nome(), dados.nacionalidade());
        return AutorResponse.de(autorRepository.save(autor));
    }

    @Transactional
    public AutorResponse atualizar(Long id, AutorRequest dados) {
        Autor autor = buscarEntidade(id);
        autor.setNome(dados.nome());
        autor.setNacionalidade(dados.nacionalidade());
        return AutorResponse.de(autor);
    }

    @Transactional
    public void excluir(Long id) {
        Autor autor = buscarEntidade(id);
        if (livroRepository.existsByAutorId(id)) {
            throw new IllegalStateException("Autor possui livros cadastrados e não pode ser excluído");
        }
        autorRepository.delete(autor);
    }

    Autor buscarEntidade(Long id) {
        return autorRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Autor " + id + " não encontrado"));
    }
}