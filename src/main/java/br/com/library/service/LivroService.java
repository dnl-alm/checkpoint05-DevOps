package br.com.library.service;

import br.com.library.dto.request.LivroRequest;
import br.com.library.dto.response.LivroResponse;
import br.com.library.exception.RecursoNaoEncontradoException;
import br.com.library.entity.Autor;
import br.com.library.entity.Livro;
import br.com.library.repository.LivroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class LivroService {

    private final LivroRepository livroRepository;
    private final AutorService autorService;

    @Transactional(readOnly = true)
    public List<LivroResponse> listar() {
        return livroRepository.findAll().stream().map(LivroResponse::de).toList();
    }

    @Transactional(readOnly = true)
    public LivroResponse buscar(Long id) {
        return LivroResponse.de(buscarEntidade(id));
    }

    @Transactional
    public LivroResponse criar(LivroRequest dados) {
        Autor autor = autorService.buscarEntidade(dados.autorId());
        Livro livro = new Livro(dados.titulo(), dados.anoPublicacao(), autor);
        return LivroResponse.de(livroRepository.save(livro));
    }

    @Transactional
    public LivroResponse atualizar(Long id, LivroRequest dados) {
        Livro livro = buscarEntidade(id);
        livro.setTitulo(dados.titulo());
        livro.setAnoPublicacao(dados.anoPublicacao());
        livro.setAutor(autorService.buscarEntidade(dados.autorId()));
        return LivroResponse.de(livro);
    }

    @Transactional
    public void excluir(Long id) {
        livroRepository.delete(buscarEntidade(id));
    }

    private Livro buscarEntidade(Long id) {
        return livroRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Livro " + id + " não encontrado"));
    }
}